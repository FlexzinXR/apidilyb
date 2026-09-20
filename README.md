# ShizukuKeyAuth

Biblioteca Swift Package para una app iOS propia. Envía una clave y un `deviceId` al endpoint configurado mediante `POST` JSON:

```json
{"key":"...","deviceId":"..."}
```

## Integración

En Xcode: **File → Add Package Dependencies… → Add Local…** y selecciona esta carpeta. También puede integrarse como dependencia local de Swift Package Manager.

```swift
import ShizukuKeyAuth

let validator = KeyValidator()
let deviceId = "id-generado-por-tu-app"

Task {
    do {
        let result = try await validator.validate(key: enteredKey, deviceId: deviceId)
        if result.ok {
            // Mostrar la pantalla autenticada.
        }
    } catch let error as KeyValidationError {
        print(error.localizedDescription)
    }
}
```

## Seguridad y alcance

La biblioteca no almacena claves, no registra secretos y no usa inyección de procesos. El `deviceId` debe ser un identificador generado y administrado por la aplicación. La autorización real debe permanecer en el servidor.

En iOS, una dylib no se distribuye normalmente como archivo suelto: se integra dentro de un framework/XCFramework y debe estar firmada junto con la app. El workflow incluido genera un `ShizukuKeyAuth.xcframework` en un runner macOS de GitHub Actions.

## Compilar sin macOS local

1. Crea un repositorio en GitHub y sube esta carpeta completa, incluyendo `.github/workflows/build-xcframework.yml`.
2. En GitHub, abre **Actions → Build iOS XCFramework → Run workflow**.
3. Cuando termine, descarga el artefacto `ShizukuKeyAuth-xcframework` desde la ejecución del workflow.

El workflow compila las variantes para dispositivo iOS y simulador y las empaqueta como XCFramework. Para instalarla en una app real todavía necesitarás firmar la app/framework con tu equipo de desarrollo de Apple; GitHub Actions no elimina ese requisito.

## Respuesta observada

La API respondió a una solicitud vacía con `400` y `{"ok":false,"code":"INVALID_REQUEST","message":"key y deviceId son obligatorios"}`. Una clave de prueba ficticia respondió `404`, que la biblioteca interpreta como clave inválida. El modelo de éxito acepta los campos `ok`, `code` y `message`; el JSON completo se conserva en `rawJSON`.

## Compilación local en Mac

```bash
xcodebuild -scheme ShizukuKeyAuth -destination 'generic/platform=iOS' -archivePath build/ios_devices.xcarchive archive SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES
xcodebuild -scheme ShizukuKeyAuth -destination 'generic/platform=iOS Simulator' -archivePath build/ios_simulator.xcarchive archive SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES
xcodebuild -create-xcframework \
  -framework build/ios_devices.xcarchive/Products/Library/Frameworks/ShizukuKeyAuth.framework \
  -framework build/ios_simulator.xcarchive/Products/Library/Frameworks/ShizukuKeyAuth.framework \
  -output build/ShizukuKeyAuth.xcframework
```
