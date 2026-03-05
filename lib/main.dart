import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

import 'providers/saved_connections_provider.dart';
import 'providers/ui_state_provider.dart';
import 'providers/workspace_provider.dart';
import 'services/workspace_service.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // Initialize Workspace directory
  final appDocDir = await getApplicationDocumentsDirectory();
  final baseOfficePath = p.join(appDocDir.path, 'remoterm_offices');

  final workspaceService = WorkspaceService(baseOfficePath: baseOfficePath);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        workspaceServiceProvider.overrideWithValue(workspaceService),
      ],
      child: const RemoteTermApp(),
    ),
  );
}

class RemoteTermApp extends ConsumerWidget {
  const RemoteTermApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'RemoteTerm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ref.watch(uiStateProvider).themeMode,
      home: const HomeScreen(),
    );
  }
}
