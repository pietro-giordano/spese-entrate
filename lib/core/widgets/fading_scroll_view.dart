import 'package:flutter/material.dart';

/// Area scorrevole che sfuma il contenuto ai bordi quando c'è altro da scorrere: in alto solo se
/// si è scesi (`extentBefore > 0`), in basso solo se resta contenuto sotto (`extentAfter > 0`).
///
/// Agisce sulla trasparenza (ShaderMask con [BlendMode.dstIn]), non sul colore: funziona uguale
/// nei due temi e su qualsiasi sfondo. Si aggiorna sia scorrendo sia quando cambia l'altezza del
/// contenuto o dell'area (liste espanse, cambio di tipo, rotazione) grazie a
/// [ScrollMetricsNotification].
class FadingScrollView extends StatefulWidget {
  const FadingScrollView({super.key, required this.children, this.padding, this.fadeExtent = 20});

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  /// Altezza della sfumatura, in px.
  final double fadeExtent;

  @override
  State<FadingScrollView> createState() => FadingScrollViewState();
}

class FadingScrollViewState extends State<FadingScrollView> {
  var _fadeTop = false;
  var _fadeBottom = false;

  /// Sfumatura in alto attiva (per i test).
  bool get fadeTop => _fadeTop;

  /// Sfumatura in basso attiva (per i test).
  bool get fadeBottom => _fadeBottom;

  bool _update(ScrollMetrics metrics) {
    final top = metrics.extentBefore > 0;
    final bottom = metrics.extentAfter > 0;
    if (top != _fadeTop || bottom != _fadeBottom) {
      setState(() {
        _fadeTop = top;
        _fadeBottom = bottom;
      });
    }
    return false; // la notifica prosegue verso l'alto
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        // Stops dei 20 px di sfumatura rispetto all'altezza reale dell'area.
        final edge = height.isFinite && height > 0 ? (widget.fadeExtent / height).clamp(0.0, 0.5) : 0.0;

        // La ShaderMask resta sempre nell'albero (cambia solo il gradiente): toglierla e rimetterla
        // ricreerebbe lo scroll e ne perderebbe la posizione.
        return ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _fadeTop ? Colors.transparent : Colors.black,
              Colors.black,
              Colors.black,
              _fadeBottom ? Colors.transparent : Colors.black,
            ],
            stops: [0, edge, 1 - edge, 1],
          ).createShader(rect),
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: (notification) => _update(notification.metrics),
            child: NotificationListener<ScrollUpdateNotification>(
              onNotification: (notification) => _update(notification.metrics),
              child: SingleChildScrollView(
                padding: widget.padding,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: widget.children),
              ),
            ),
          ),
        );
      },
    );
  }
}
