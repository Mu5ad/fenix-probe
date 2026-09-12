import SwiftUI
import UIKit
import CoreLocation

// PROYECTO FENIX - Fase 0: registrador de lanzamientos de la app.
// Cada linea = un lanzamiento (incluidos los automaticos en segundo plano tras un reinicio).

final class FenixLog: ObservableObject {
    static let shared = FenixLog()
    @Published var lines: [String] = []
    let fileURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("fenix-log.txt")

    func record(_ reason: String) {
        let now = Date()
        let uptime = ProcessInfo.processInfo.systemUptime
        let boot = Date(timeIntervalSinceNow: -uptime)
        let iso = ISO8601DateFormatter()
        let state: String
        switch UIApplication.shared.applicationState {
        case .active: state = "ACTIVE"
        case .inactive: state = "INACTIVE"
        case .background: state = "BACKGROUND"
        default: state = "UNKNOWN"
        }
        let data = UIApplication.shared.isProtectedDataAvailable ? "desbloqueado" : "BLOQUEADO"
        let line = "\(iso.string(from: now)) | boot~\(iso.string(from: boot)) | uptime=\(Int(uptime))s | why=\(reason) | state=\(state) | datos=\(data) | bgrestante=\(Int(UIApplication.shared.backgroundTimeRemaining))s"
        append(line)
        reload()
    }

    func append(_ line: String) {
        let text = line + "\n"
        if FileManager.default.fileExists(atPath: fileURL.path) {
            if let h = try? FileHandle(forWritingTo: fileURL) {
                h.seekToEndOfFile()
                if let d = text.data(using: .utf8) { h.write(d) }
                try? h.close()
            }
        } else {
            try? text.write(to: fileURL, atomically: true, encoding: .utf8)
        }
        try? FileManager.default.setAttributes([.protectionKey: FileProtectionType.none], ofItemAtPath: fileURL.path)
    }

    func reload() {
        if let content = try? String(contentsOf: fileURL, encoding: .utf8) {
            lines = content.split(separator: "\n").map(String.init).reversed()
        } else {
            lines = []
        }
    }

    func clearLog() {
        try? FileManager.default.removeItem(at: fileURL)
        reload()
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, CLLocationManagerDelegate {
    var lm: CLLocationManager?
    var bgID: UIBackgroundTaskIdentifier = .invalid

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        var why = "didFinishLaunching"
        if let opts = launchOptions, !opts.isEmpty {
            why += "(" + opts.keys.map { $0.rawValue }.joined(separator: ",") + ")"
        }
        FenixLog.shared.record(why)

        bgID = application.beginBackgroundTask(withName: "fenix-bg") { [weak self] in
            guard let self = self else { return }
            if self.bgID != .invalid {
                application.endBackgroundTask(self.bgID)
                self.bgID = .invalid
            }
        }

        let lm = CLLocationManager()
        lm.delegate = self
        lm.requestAlwaysAuthorization()
        lm.startMonitoringSignificantLocationChanges()
        self.lm = lm

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) { FenixLog.shared.record("didEnterBackground") }
    func applicationWillEnterForeground(_ application: UIApplication) { FenixLog.shared.record("willEnterForeground") }
    func applicationDidBecomeActive(_ application: UIApplication) { FenixLog.shared.record("didBecomeActive") }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        FenixLog.shared.record("locationUpdate")
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        FenixLog.shared.record("locationAuth=\(manager.authorizationStatus.rawValue)")
    }
}

@main
struct FenixProbeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @ObservedObject var log = FenixLog.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FENIX PROBE")
                .font(.headline)
            Text("Registro de arranques. Reinicia el iPad y vuelve aqui: cada linea es un lanzamiento de la app, incluidos los automaticos en segundo plano.")
                .font(.caption)

            HStack(spacing: 12) {
                Button("Registrar ahora") { log.record("manual") }
                Button("Copiar todo") { UIPasteboard.general.string = log.lines.joined(separator: "\n") }
                Button("Vaciar") { log.clearLog() }
            }
            .font(.footnote)

            Text("Lineas: \(log.lines.count)")
                .font(.caption)

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(log.lines.enumerated()), id: \.offset) { _, l in
                        Text(l)
                            .font(.system(size: 10, design: .monospaced))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .onAppear { log.reload() }
    }
}
