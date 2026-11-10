import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/entities/perfil_trabajadora.dart';
import '../../domain/entities/tipo_limpieza.dart';
import '../../domain/entities/zona.dart';
import '../../domain/repositories/perfil_repository.dart';

/// Implementación de PerfilRepository usando Supabase.
///
/// Es la ÚNICA parte de la app que habla con Supabase para el perfil de la
/// trabajadora. Los permisos (qué columnas se pueden escribir) están en la
/// migración `..._seguridad_rls.sql`.
class SupabasePerfilRepository implements PerfilRepository {
  SupabasePerfilRepository(this._client);

  final SupabaseClient _client;

  static const _bucketAvatars = 'avatars';

  String get _uid {
    final usuario = _client.auth.currentUser;
    if (usuario == null) {
      throw const AppException('No pudimos identificar tu cuenta.');
    }
    return usuario.id;
  }

  @override
  Future<List<Zona>> zonasDisponibles() async {
    try {
      final filas = await _client.from('zonas').select().order('nombre');
      return [
        for (final fila in filas) Zona.desdeFila(fila),
      ];
    } on Exception {
      throw const AppException('No pudimos cargar las zonas.');
    }
  }

  @override
  Future<PerfilTrabajadora> miPerfil() async {
    final uid = _uid;
    try {
      final trabajadora = await _client
          .from('trabajadoras')
          .select()
          .eq('id', uid)
          .maybeSingle();
      final perfil =
          await _client.from('perfiles').select('foto_path').eq('id', uid).maybeSingle();
      final filasZonas = await _client
          .from('trabajadora_zonas')
          .select('zonas(id, nombre, municipio, parroquia)')
          .eq('trabajadora_id', uid);
      final filasServicios = await _client
          .from('trabajadora_servicios')
          .select('tipo')
          .eq('trabajadora_id', uid);

      final zonas = [
        for (final fila in filasZonas)
          if (fila['zonas'] != null)
            Zona.desdeFila(fila['zonas'] as Map),
      ]..sort((a, b) => a.nombre.compareTo(b.nombre));

      final fotoPath = perfil?['foto_path'] as String?;

      return PerfilTrabajadora(
        zonas: zonas,
        servicios: [
          for (final fila in filasServicios) TipoLimpieza.desdeDb(fila['tipo'] as String),
        ],
        experienciaAnios: (trabajadora?['experiencia_anios'] as num?)?.toInt(),
        tarifaReferencia: (trabajadora?['tarifa_referencia'] as num?)?.toDouble(),
        descripcion: trabajadora?['descripcion'] as String?,
        fotoUrl: fotoPath == null
            ? null
            : _client.storage.from(_bucketAvatars).getPublicUrl(fotoPath),
      );
    } on AppException {
      rethrow;
    } on Exception {
      throw const AppException('No pudimos cargar tu perfil.');
    }
  }

  @override
  Future<void> guardarPerfil({
    required List<int> zonasIds,
    required List<TipoLimpieza> servicios,
    int? experienciaAnios,
    double? tarifaReferencia,
    String? descripcion,
  }) async {
    final uid = _uid;
    try {
      await _client.from('trabajadoras').update({
        'experiencia_anios': experienciaAnios,
        'tarifa_referencia': tarifaReferencia,
        'descripcion': descripcion,
      }).eq('id', uid);

      // Las zonas y los servicios se reemplazan completos (borrar y volver a
      // insertar): así quitar una zona la borra de verdad.
      await _client.from('trabajadora_zonas').delete().eq('trabajadora_id', uid);
      if (zonasIds.isNotEmpty) {
        await _client.from('trabajadora_zonas').insert([
          for (final id in zonasIds) {'trabajadora_id': uid, 'zona_id': id},
        ]);
      }

      await _client.from('trabajadora_servicios').delete().eq('trabajadora_id', uid);
      if (servicios.isNotEmpty) {
        await _client.from('trabajadora_servicios').insert([
          for (final servicio in servicios)
            {'trabajadora_id': uid, 'tipo': servicio.valorDb},
        ]);
      }
    } on Exception {
      throw const AppException('No pudimos guardar tu perfil. Intenta de nuevo.');
    }
  }

  @override
  Future<String> subirFoto({
    required List<int> bytes,
    required String nombreArchivo,
  }) async {
    final uid = _uid;

    // Criterio 4: solo JPG o PNG.
    final nombre = nombreArchivo.toLowerCase();
    final esPng = nombre.endsWith('.png');
    final esJpg = nombre.endsWith('.jpg') || nombre.endsWith('.jpeg');
    if (!esPng && !esJpg) {
      throw const AppException('La foto debe ser JPG o PNG');
    }

    // Criterio 4: nada de más de 5 MB.
    if (bytes.length > AppConstants.tamanoMaximoFotoBytes) {
      throw const AppException('La foto no puede pasar de 5 MB');
    }

    final ruta = '$uid/perfil.${esPng ? 'png' : 'jpg'}';
    try {
      await _client.storage.from(_bucketAvatars).uploadBinary(
        ruta,
        Uint8List.fromList(bytes),
        fileOptions: FileOptions(
          contentType: esPng ? 'image/png' : 'image/jpeg',
          upsert: true,
        ),
      );
      // La ruta se guarda en el perfil; si algo falla antes, la foto anterior
      // queda intacta.
      await _client.from('perfiles').update({'foto_path': ruta}).eq('id', uid);
      return _client.storage.from(_bucketAvatars).getPublicUrl(ruta);
    } on AppException {
      rethrow;
    } on Exception {
      throw const AppException('No pudimos subir la foto. Intenta de nuevo.');
    }
  }
}
