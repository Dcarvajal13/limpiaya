/// HU-41 · Datos personales editables de cualquier cuenta.
///
/// El nombre se muestra en la app; el teléfono es privado y solo lo usa el
/// equipo para contacto. Es una entidad del dominio: no sabe de Supabase.
class DatosPersonales {
  const DatosPersonales({required this.nombre, required this.telefono});

  final String nombre;
  final String telefono;
}
