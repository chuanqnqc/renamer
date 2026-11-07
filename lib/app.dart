import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/rename_session.dart';
import 'ui/home_page.dart';

class FileRenamerApp extends StatelessWidget {
  const FileRenamerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RenameSession(),
      child: MaterialApp(
        title: 'FileRenamer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2F6F4E),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          visualDensity: VisualDensity.comfortable,
        ),
        home: const HomePage(),
      ),
    );
  }
}
