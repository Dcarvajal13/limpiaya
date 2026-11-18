import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Cuadrícula donde TODAS las cajas miden lo mismo: el ancho de una columna
/// y el alto de la caja más alta de toda la lista (no solo de su fila).
///
/// Así ninguna solicitud se ve más larga o más corta que las demás, aunque
/// una tenga una insignia de más ("Te invitaron") o un texto más largo.
///
/// Las cajas deben repartir su espacio con `Spacer` o
/// `MainAxisAlignment.spaceBetween` para que los botones queden abajo.
/// El alto se mide igual que `IntrinsicHeight`.
class CuadriculaIgual extends MultiChildRenderObjectWidget {
  const CuadriculaIgual({
    super.key,
    required this.columnas,
    this.espacio = 16,
    this.espacioFilas = 16,
    required super.children,
  }) : assert(columnas > 0);

  final int columnas;

  /// Espacio entre columnas.
  final double espacio;

  /// Espacio entre filas.
  final double espacioFilas;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderCuadriculaIgual(
        columnas: columnas,
        espacio: espacio,
        espacioFilas: espacioFilas,
      );

  @override
  void updateRenderObject(BuildContext context, RenderCuadriculaIgual renderObject) {
    renderObject
      ..columnas = columnas
      ..espacio = espacio
      ..espacioFilas = espacioFilas;
  }
}

/// Posición de cada caja dentro de [CuadriculaIgual].
class DatosCuadriculaIgual extends ContainerBoxParentData<RenderBox> {}

/// Lo que dibuja [CuadriculaIgual].
class RenderCuadriculaIgual extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, DatosCuadriculaIgual>,
        RenderBoxContainerDefaultsMixin<RenderBox, DatosCuadriculaIgual> {
  RenderCuadriculaIgual({
    required int columnas,
    required double espacio,
    required double espacioFilas,
  })  : _columnas = columnas,
        _espacio = espacio,
        _espacioFilas = espacioFilas;

  int _columnas;
  set columnas(int valor) {
    if (valor == _columnas) return;
    _columnas = valor;
    markNeedsLayout();
  }

  double _espacio;
  set espacio(double valor) {
    if (valor == _espacio) return;
    _espacio = valor;
    markNeedsLayout();
  }

  double _espacioFilas;
  set espacioFilas(double valor) {
    if (valor == _espacioFilas) return;
    _espacioFilas = valor;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! DatosCuadriculaIgual) {
      child.parentData = DatosCuadriculaIgual();
    }
  }

  double _anchoCaja(double ancho) =>
      math.max(0.0, (ancho - _espacio * (_columnas - 1)) / _columnas);

  /// Alto de la caja más alta si cada una mide [anchoCaja] de ancho.
  double _altoCaja(double anchoCaja) {
    var alto = 0.0;
    var hijo = firstChild;
    while (hijo != null) {
      alto = math.max(alto, hijo.getMaxIntrinsicHeight(anchoCaja));
      hijo = childAfter(hijo);
    }
    return alto;
  }

  double _altoTotal(double altoCaja) {
    final filas = (childCount / _columnas).ceil();
    if (filas == 0) return 0;
    return filas * altoCaja + (filas - 1) * _espacioFilas;
  }

  @override
  void performLayout() {
    final ancho = constraints.maxWidth;
    final anchoCaja = _anchoCaja(ancho);
    final alto = _altoCaja(anchoCaja);

    var i = 0;
    var hijo = firstChild;
    while (hijo != null) {
      hijo.layout(BoxConstraints.tight(Size(anchoCaja, alto)));
      final columna = i % _columnas;
      final fila = i ~/ _columnas;
      (hijo.parentData! as DatosCuadriculaIgual).offset = Offset(
        columna * (anchoCaja + _espacio),
        fila * (alto + _espacioFilas),
      );
      i++;
      hijo = childAfter(hijo);
    }

    size = constraints.constrain(Size(ancho, _altoTotal(alto)));
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final ancho = constraints.maxWidth;
    return constraints.constrain(
      Size(ancho, _altoTotal(_altoCaja(_anchoCaja(ancho)))),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _altoTotal(_altoCaja(_anchoCaja(width)));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _altoTotal(_altoCaja(_anchoCaja(width)));

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
