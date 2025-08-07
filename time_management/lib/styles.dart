import 'package:flutter/material.dart';
import 'package:time_management/app_state_container.dart';

class AppStyles {
  static const TextStyle defaultFont = TextStyle(fontFamily: "Crimson Pro");

  static TextStyle pageHeader(context) {
    return defaultFont.copyWith(fontSize: AppFontSizes.header3);
  }

  static TextStyle actionButtonText(context) {
    return defaultFont.copyWith(
        fontSize: AppFontSizes.header3,
        color: StateContainer.of(context)?.currTheme.lightText);
  }

  static TextStyle inputTitle(context) {
    return defaultFont.copyWith(
        fontSize: AppFontSizes.body,
        fontWeight: FontWeight.w800,
        color: StateContainer.of(context)?.currTheme.text);
  }

  static TextStyle inputHint(context) {
    return defaultFont.copyWith(
        fontSize: AppFontSizes.paragraph,
        color: StateContainer.of(context)?.currTheme.hintText);
  }

  static TextStyle inputText(context) {
    return defaultFont.copyWith(
        fontSize: AppFontSizes.paragraph,
        color: StateContainer.of(context)?.currTheme.text);
  }

  static TextStyle dateHeader(context) {
    return defaultFont.copyWith(
      fontSize: AppFontSizes.header3,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w700,
      color: StateContainer.of(context)?.currTheme.text,
      height: 0.95,
    );
  }

  static TextStyle subDateHeader(context) {
    return defaultFont.copyWith(
      fontSize: AppFontSizes.paragraph,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w700,
      color: StateContainer.of(context)?.currTheme.text,
      height: 0.95,
    );
  }

  static TextStyle dateMetaHeader(context) {
    return defaultFont.copyWith(
      fontSize: AppFontSizes.meta,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w600,
      color: StateContainer.of(context)?.currTheme.text,
    );
  }

  static TextStyle tabTitle(context) {
    return defaultFont.copyWith(
        color: StateContainer.of(context)?.currTheme.text,
        fontSize: AppFontSizes.paragraph,
        fontWeight: FontWeight.w700);
  }

  static TextStyle loadingText(context) {
    return defaultFont.copyWith(
        color: StateContainer.of(context)?.currTheme.text,
        fontSize: AppFontSizes.header2,
        fontWeight: FontWeight.w700);
  }
}

class AppFontSizes {
  static const header0 = 72.0;
  static const header1 = 48.0;
  static const header2 = 32.0;
  static const header3 = 24.0;
  static const body = 18.0;
  static const paragraph = 16.0;
  static const meta = 14.0;
  static const footNote = 12.0;
}
