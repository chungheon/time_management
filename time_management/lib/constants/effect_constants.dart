import 'package:flutter/material.dart';
import 'package:time_management/app_state_container.dart';

class EffectConstants {
  static BoxShadow shadowEffectDown(context) {
    return BoxShadow(
      color: StateContainer.of(context)?.currTheme.shadowEffect ??
          Colors.black.withOpacity(0.25),
      blurRadius: 4.0,
      offset: const Offset(0, 4.0),
    );
  }

    static BoxShadow shadowEffectUp(context) {
    return BoxShadow(
      color: StateContainer.of(context)?.currTheme.shadowEffect ??
          Colors.black.withOpacity(0.25),
      blurRadius: 4.0,
      offset: const Offset(0, -4.0),
    );
  }
}
