import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

class FlowbyteApp extends StatelessWidget {
  const FlowbyteApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'FLOWBYTE',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    routerConfig: appRouter,
  );
}
