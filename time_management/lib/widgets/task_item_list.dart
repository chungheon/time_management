import 'package:flutter/material.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/constants/effect_constants.dart';

class TaskItemList extends StatelessWidget {
  const TaskItemList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: StateContainer.of(context)?.currTheme.listItemBackground,
        borderRadius: BorderRadius.circular(5.0),
        boxShadow: [
          EffectConstants.shadowEffectDown(context),
        ],
      ),
    );
  }
}
