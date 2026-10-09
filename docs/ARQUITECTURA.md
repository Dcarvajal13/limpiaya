# Arquitectura de LimpiaYa

El código está organizado **por capas**. Cada capa tiene una responsabilidad y solo puede usar las capas que están debajo de ella.

```
┌─────────────────────────────────────────────┐
│  presentation/   Pantallas, widgets, estado │  ← lo que ve el usuario
└───────────────────────┬─────────────────────┘
                        │ usa
┌───────────────────────▼─────────────────────┐
│  domain/   Entidades y contratos            │  ← reglas del negocio (no sabe de Supabase)
└───────────────────────▲─────────────────────┘
                        │ implementa
┌───────────────────────┴─────────────────────┐
│  data/   Repositorios que hablan con        │  ← lo ÚNICO que conoce Supabase
│          Supabase                           │
└─────────────────────────────────────────────┘

core/   Configuración, tema, rutas, validaciones (lo usan todas las capas)
```

**Regla de oro:** las pantallas **nunca** importan `supabase_flutter`. Le piden los datos a un repositorio del dominio.

## Qué va en cada carpeta

```
lib/
├── main.dart                  Arranca Supabase y la app
├── app.dart                   Conecta el tema y las rutas
│
├── core/
│   ├── config/env.dart        Lee las claves de env.json
│   ├── constants/             Valores fijos (comisión 10 %, largo de contraseña…)
│   ├── di/providers.dart      Decide qué implementación usa cada repositorio
│   ├── errors/                AppException: errores con mensaje en español
│   ├── router/                Rutas (URLs) y protección de pantallas
│   ├── theme/                 Colores y estilos del Figma
│   └── utils/validadores.dart Validaciones de formularios
│
├── domain/
│   ├── entities/              Usuario, RolUsuario, (luego Perfil, Solicitud…)
│   └── repositories/          Contratos: QUÉ datos se pueden pedir
│
├── data/
│   ├── models/                Conversión JSON de Supabase ⇄ entidad
│   └── repositories/          CÓMO se piden: llamadas a Supabase
│
└── presentation/
    ├── providers/             Estado de las pantallas (Riverpod)
    ├── screens/               Una carpeta por módulo: auth/, cliente/, trabajadora/, admin/
    └── widgets/               Componentes reutilizables
```

## Receta: cómo programar una historia

Ejemplo con **HU-01 · Registrarme eligiendo mi rol**:

1. **Dominio:** ¿existe el método en el contrato? `AuthRepository.registrarse(...)` ya está declarado. Si tu historia necesita uno nuevo, agrégalo al contrato.
2. **Data:** implementa el método en `SupabaseAuthRepository` (busca el `TODO(HU-01)`). Convierte los errores de Supabase en `AppException` con el mensaje del criterio de aceptación.
3. **Presentation, estado:** si la pantalla necesita manejar "cargando / error / listo", crea un provider en `presentation/providers/`.
4. **Presentation, pantalla:** construye el formulario en `screens/auth/registro_screen.dart` según el Figma. Usa `Validadores` de `core/utils`.
5. **Rutas:** si tu pantalla es nueva, agrégala en `core/router/rutas.dart` y `app_router.dart`.
6. **Prueba:** `flutter analyze`, `flutter test` y pruébalo en Chrome (computadora y teléfono).

### Para una funcionalidad nueva con datos (por ejemplo, solicitudes)

```
domain/entities/solicitud.dart                    → class Solicitud { ... }
domain/repositories/solicitud_repository.dart     → abstract interface class SolicitudRepository
data/models/solicitud_model.dart                  → Solicitud desde/hacia JSON
data/repositories/supabase_solicitud_repository.dart → implements SolicitudRepository
core/di/providers.dart                            → solicitudRepositoryProvider
presentation/screens/cliente/...                  → las pantallas
```

## Cómo usar un repositorio desde una pantalla

```dart
class MiPantalla extends ConsumerWidget {
  const MiPantalla({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authRepositoryProvider);   // ✅ contrato del dominio
    // Supabase.instance.client...                    // ❌ nunca en una pantalla
    ...
  }
}
```

## Decisiones tomadas

| Tema | Decisión | Por qué |
|---|---|---|
| Estado | Riverpod | Estándar en Flutter, fácil de probar, encaja con las capas |
| Navegación | go_router | URLs reales en la web y protección de pantallas sin sesión |
| Claves | `env.json` + `--dart-define-from-file` | Nada de claves en el repositorio (HD-01, criterio 3) |
| Plataforma | Web primero; Android/iOS listos | Sin `dart:html`, así el mismo código sirve para la app móvil |
