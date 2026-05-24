import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:window_manager/window_manager.dart';
import 'package:fugrade_automation/core/theme/app_theme.dart';
import 'package:fugrade_automation/data/datasources/cmt_writer_datasource.dart';
import 'package:fugrade_automation/data/datasources/fg_parser_datasource.dart';
import 'package:fugrade_automation/data/datasources/local_storage_datasource.dart';
import 'package:fugrade_automation/data/datasources/sheets_api_datasource.dart';
import 'package:fugrade_automation/domain/services/contribution_merge_service.dart';
import 'package:fugrade_automation/domain/services/matching_service.dart';
import 'package:fugrade_automation/presentation/blocs/cmt_editor/cmt_editor_bloc.dart';
import 'package:fugrade_automation/presentation/blocs/export/export_bloc.dart';
import 'package:fugrade_automation/presentation/blocs/fg_loader/fg_loader_bloc.dart';
import 'package:fugrade_automation/presentation/blocs/sheet_sync/sheet_sync_bloc.dart';
import 'package:fugrade_automation/presentation/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const options = WindowOptions(center: true, title: 'FuGrade Automation');

  windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.maximize();
    await windowManager.focus();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!await windowManager.isMaximized()) {
      await windowManager.maximize();
    }
  });

  runApp(const FuGradeApp());
}

class FuGradeApp extends StatelessWidget {
  const FuGradeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => FgParserDatasource()),
        RepositoryProvider(create: (_) => SheetsApiDatasource()),
        RepositoryProvider(create: (_) => LocalStorageDatasource()),
        RepositoryProvider(create: (_) => CmtWriterDatasource()),
        RepositoryProvider(create: (_) => MatchingService()),
        RepositoryProvider(create: (_) => ContributionMergeService()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (ctx) => FgLoaderBloc(ctx.read<FgParserDatasource>()),
          ),
          BlocProvider(
            create: (ctx) => SheetSyncBloc(
              ctx.read<SheetsApiDatasource>(),
              ctx.read<MatchingService>(),
            ),
          ),
          BlocProvider(
            create: (ctx) => CmtEditorBloc(
              ctx.read<LocalStorageDatasource>(),
              ctx.read<SheetsApiDatasource>(),
            ),
          ),
          BlocProvider(
            create: (ctx) => ExportBloc(ctx.read<CmtWriterDatasource>()),
          ),
        ],
        child: MaterialApp(
          title: 'FuGrade Automation',
          theme: AppTheme.light,
          debugShowCheckedModeBanner: false,
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
