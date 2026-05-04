# Proyecto Final - Programación Avanzada de Apps

Aplicación Flutter para identificar razas de perros usando un modelo TFLite, consultar información de la raza desde TheDogAPI, y obtener videos de cuidados desde YouTube.

## Descripción

Esta aplicación está diseñada con una base de arquitectura limpia, donde la carpeta `lib/domain` contiene las entidades, repositorios y casos de uso del dominio.

- `domain`: capa de dominio, contiene entidades, repositorios abstractos y casos de uso.
- `data`: capa de datos, contiene implementaciones de repositorios, datasources y servicios.
- `presentation`: capa de presentación, contiene pantallas, widgets, proveedores y rutas.

## Características

- Identificación de raza de perro desde una imagen usando TFLite.
- Búsqueda de información de raza desde TheDogAPI.
- Búsqueda de videos de cuidados en YouTube.
- Historial de escaneos guardado en Firestore.
- Favoritos y detalles de raza.
- Uso de Riverpod para gestión de estado.

## Dependencias principales

- `flutter_riverpod`
- `go_router`
- `dio`
- `http`
- `tflite_flutter`
- `image`
- `camera`
- `image_picker`
- `url_launcher`
- `cloud_firestore`
- `firebase_storage`

## Estructura del proyecto

```text
lib/
  domain/
    entities/
    repositories/
    use_cases/
  data/
    data_sources/
    repositories/
    models/
  presentation/
    providers/
    screens/
    widgets/
    routes/
```

## Configuración y ejecución

1. Clonar el repositorio.
2. Verificar que el entorno de Flutter esté instalado.
3. Ejecutar:
   ```bash
   flutter pub get
   flutter run
   ```
4. Para usar Firebase, configurarlo en `firebase_options.dart` y mantener los archivos de configuración (`google-services.json`, `GoogleService-Info.plist`) presentes.

## Arquitectura limpia

La aplicación separa las responsabilidades en capas:

- `domain`: define lo que la aplicación hace, sin detalles de implementación.
- `data`: implementa las dependencias externas (APIs, base de datos, modelo ML) y traduce datos hacia/desde el dominio.
- `presentation`: construye la interfaz y consume casos de uso a través de proveedores.

## Notas

- Las claves de API deben manejarse de forma segura en un entorno real y no en el código fuente.
- El modelo TFLite y las etiquetas están en `assets/models/`.
- La aplicación depende de Firebase para el historial y favoritos.



