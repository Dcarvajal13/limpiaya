# Cómo trabajamos en LimpiaYa

## Ramas

### 🟢 `main`
La versión oficial. Solo se actualiza al **final de cada sprint**, antes del Sprint Review, con un PR desde `develop`. Es lo que se publica en la página de demo.
❌ Nadie trabaja aquí directamente (está protegida).

### 🔵 `develop`
Donde se junta el trabajo de todos durante el sprint. Cada historia terminada entra aquí con un Pull Request.
❌ Nadie trabaja aquí directamente (está protegida).

### 🟡 Ramas de tarea: aquí trabaja cada quien
**Una rama por cada tarjeta de Trello.** Sale de `develop` y vuelve a `develop` con un PR.

| Tipo | Formato | Ejemplo |
|---|---|---|
| Historia de usuario | `feature/HU-XX-descripcion` | `feature/HU-01-registro` |
| Historia de desarrollador | `chore/HD-XX-descripcion` | `chore/HD-03-tablas` |
| Corregir un error | `fix/descripcion` | `fix/login-no-redirige` |

### Reglas
1. Siempre crear la rama desde `develop` actualizado.
2. Una rama = una tarjeta. No mezclar tarjetas en la misma rama.
3. Nadie trabaja en la rama de otro.
4. Todo entra a `develop` con un PR y el CI en verde. **Cada quien hace el merge de su propio PR**; no hace falta esperar aprobación.
5. Después del merge, la rama se borra.
6. Ramas cortas: idealmente se cierran en 1 a 3 días.

## Paso a paso de una tarjeta

```bash
# 1. Empezar
git checkout develop
git pull
git checkout -b feature/HU-XX-descripcion
# → En Trello: mover la tarjeta a 🔨 En Proceso

# 2. Mientras trabajas (todas las veces que quieras)
git add .
git commit -m "feat(HU-XX): lo que hiciste"
git push -u origin feature/HU-XX-descripcion

# 3. Antes de abrir el PR
flutter analyze   # debe decir "No issues found!"
flutter test      # debe decir "All tests passed!"

# 4. Abrir el PR
gh pr create --base develop

# 5. Cuando el CI esté en ✅ verde, hacer el merge
gh pr merge --merge --delete-branch
# → En Trello: mover la tarjeta a 🧪 Pruebas y avisar en el grupo
```

Si no tienes `gh`, después del `git push` entra al repo en GitHub y dale al botón **Compare & pull request**.

### Si `develop` avanzó mientras trabajabas
```bash
git checkout develop
git pull
git checkout feature/HU-XX-descripcion
git merge develop
```

## Mensajes de commit

Formato: `tipo(TARJETA): qué hiciste`, en presente y en español.

| Tipo | Cuándo | Ejemplo |
|---|---|---|
| `feat` | Algo nuevo de una historia | `feat(HU-01): formulario de registro` |
| `fix` | Corregir un error | `fix(HU-02A): mensaje de contraseña incorrecta` |
| `chore` | Configuración, dependencias | `chore(HD-05): publicar en GitHub Pages` |
| `docs` | Documentación | `docs: explicar cómo correr el proyecto` |
| `test` | Pruebas | `test(HU-01): validar teléfono` |

## Probar la historia de un compañero (🧪 Pruebas)

La Definición de Hecho pide que otra persona pruebe cada historia antes de pasarla a ✅ Hecho.

1. Trae lo último de `develop` y córrelo:
   ```bash
   git checkout develop
   git pull
   flutter run -d chrome --dart-define-from-file=env.json
   ```
2. Revisa que cumpla los criterios de aceptación de la tarjeta y la Definición de Hecho.
3. Si cumple, mueve la tarjeta a ✅ Hecho. Si no, coméntalo en la tarjeta y vuelve a 🔨 En Proceso.

## Reglas de código

- **Las pantallas nunca llaman a Supabase directo.** Ver [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md).
- **Nada solo-web:** no usar `dart:html` ni `package:web`. Queremos poder sacar la app móvil después.
- **Nada de claves en el código.** Todo va en `env.json`.
- **Colores y estilos** desde `core/theme`, nunca escritos a mano en la pantalla.
- **Textos en español** y con los mensajes exactos de los criterios de aceptación.
