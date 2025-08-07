import 'package:flutter/material.dart';
import 'package:time_management/theme.dart';

class _InheritedStateContainer extends InheritedWidget {
  final StateContainerState data;

  const _InheritedStateContainer({
    Key? key,
    required this.data,
    required Widget child,
  }) : super(key: key, child: child);

  // This is a built in method which you can use to check if
  // any state has changed. If not, no reason to rebuild all the widgets
  // that rely on your state.
  @override
  bool updateShouldNotify(_InheritedStateContainer old) => true;
}

class StateContainer extends StatefulWidget {
  const StateContainer({super.key, required this.child});

  static StateContainerState? of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<_InheritedStateContainer>()
            ?.data;
  }

  final Widget child;
  @override
  StateContainerState createState() => StateContainerState();
}

class StateContainerState extends State<StateContainer> {
  BaseTheme currTheme = LightTheme();

  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

  int count = 0;
  @override
  Widget build(BuildContext context) {
    return _InheritedStateContainer(data: this, child: widget.child);
  }

  void updateTheme() {
    //For updating theme call setstate in this function to globally change theme
    // List<Color> colors = [
    //   LightTheme.teal,
    //   LightTheme.black,
    //   LightTheme.pink,
    // ];
    // setState(() {
    //   currTheme.primary = colors[count % colors.length];
    //   currTheme.button = colors[count % colors.length];
    // });
  }
}