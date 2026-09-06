import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

/// Einstiegspunkt. Der [ProviderScope] hält den gesamten App-Zustand
/// (vorerst In-Memory-Fakes, siehe README).
void main() {
  runApp(const ProviderScope(child: TagebuchApp()));
}
