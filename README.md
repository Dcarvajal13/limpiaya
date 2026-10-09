# LimpiaYa

Página web tipo "Airbnb de la limpieza" que conecta hogares de Caracas con trabajadoras de limpieza verificadas.

Proyecto de **Ingeniería de Software · UNIMET**. Equipo: Derek Carvajal, Ruben Dos Santos, Anthony Caldera y Gloria Fernandes. Profesora: Keyla Rivas.

**Tecnologías:** Flutter (web) · Supabase · Riverpod · go_router

---

## Cómo correr el proyecto

1. Tener **Flutter 3.38.x** (`flutter --version`).
2. Clonar el repo:
   ```bash
   git clone https://github.com/Dcarvajal13/limpiaya.git
   cd limpiaya
   flutter pub get
   ```
3. Crear `env.json` en la raíz (al lado de `pubspec.yaml`). Pídele el contenido a un integrante del equipo:
   ```json
   {
     "SUPABASE_URL": "https://xxxx.supabase.co",
     "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_..."
   }
   ```
   ⚠️ `env.json` **nunca** se sube al repo (ya está en `.gitignore`).
4. Correr:
   ```bash
   flutter run -d chrome --dart-define-from-file=env.json
   ```
   O en VS Code: **F5** (ya está configurado en `.vscode/launch.json`).

## Documentación del equipo

- [CONTRIBUTING.md](CONTRIBUTING.md): ramas, commits y pull requests. **Léelo antes de empezar.**
- [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md): cómo está organizado el código y receta para programar una historia.

## Comandos útiles

| Comando | Para qué |
|---|---|
| `flutter analyze` | Revisa errores y malas prácticas. Debe decir "No issues found!" antes de un PR |
| `flutter test` | Corre las pruebas |
| `dart format lib test` | Ordena el formato del código |
