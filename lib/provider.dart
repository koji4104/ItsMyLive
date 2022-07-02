import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'common.dart';

final isSaverProvider = StateProvider<bool>((ref) {
  return false;
});

final isRunningProvider = StateProvider<bool>((ref) {
  return false;
});

final isConnectingProvider = StateProvider<bool>((ref) {
  return false;
});
