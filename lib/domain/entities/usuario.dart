/// Usuario con sesión iniciada.
///
/// Es una entidad del dominio: no sabe nada de Supabase.
/// Cuando existan las tablas (HD-03) se agregará la entidad Perfil
/// con nombre, rol, teléfono y foto.
class Usuario {
  const Usuario({required this.id, required this.email});

  final String id;
  final String email;
}
