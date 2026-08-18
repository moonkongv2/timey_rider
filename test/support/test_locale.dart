import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void setTestLocale(WidgetTester tester, Locale locale) {
  final dispatcher = tester.binding.platformDispatcher;
  dispatcher.localeTestValue = locale;
  dispatcher.localesTestValue = [locale];
  addTearDown(dispatcher.clearLocaleTestValue);
  addTearDown(dispatcher.clearLocalesTestValue);
}
