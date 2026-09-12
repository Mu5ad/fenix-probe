# FenixProbe — PROYECTO FENIX (Fase 0)

App de medida para el experimento **FENIX**: comprobar si iOS relanza automaticamente
una app permafirmada en segundo plano **nada mas arrancar el sistema**, y si eso ocurre
**antes o despues del primer desbloqueo**.

- iPad objetivo: iPad Air 2 (iPad5,3, A8X), iPadOS 15.7.7.
- Declara los modos `voip`, `location` y `bluetooth-central` (los candidatos documentados
  con relanzamiento pre-desbloqueo).
- Escribe cada lanzamiento en `fenix-log.txt` (Documents, visible en la app Archivos).

## Instalacion (TrollStore, sin certificados)
1. Descarga el `.ipa` desde la seccion **Releases** de este repositorio (con Safari en el iPad).
2. Abre **TrollStore** -> pestana Apps -> boton **+** -> elige el `.ipa` -> Install.
3. Abre **FenixProbe** una vez (para que el sistema la registre).

## Protocolo de medida (2 minutos)
1. Con la app abierta, **reinicia el iPad** (no lo desbloquees).
2. Espera **3 minutos** sin tocar nada (que arranque, coja red...).
3. Desbloquea, abre la app y mira las lineas con hora.
4. Repite el ciclo 3 veces y guarda el log (boton **Copiar todo** o Archivos -> FenixProbe -> fenix-log.txt).

## Que buscamos
- Una linea con `why=didFinishLaunching` y `state=BACKGROUND` cuya hora sea **pocos minutos
  despues del reinicio** = iOS relanzo la app sola.
- Si esa linea aparece ademas con `datos=BLOQUEADO` = **relanzada ANTES del desbloqueo**. Eso
  es exactamente lo que necesita la Fase 1 (auto-jailbreak sin tocar nada).

## Notas
- Sin firma: este IPA es unsigned; se instala con TrollStore (permisign).
- Compilado en GitHub Actions (macos-15). Pipeline compartido con el resto de apps del usuario.
