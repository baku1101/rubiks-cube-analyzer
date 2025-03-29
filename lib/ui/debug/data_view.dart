import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rubiks_cube_analyzer/services/gan/protocol/response.dart';
import 'package:rubiks_cube_analyzer/ui/debug/cube_state_view.dart';
import 'package:rubiks_cube_analyzer/ui/debug/debug_screen.dart';

/// データログとキューブの状態を表示するデバッグビュー
class DataView extends StatelessWidget {
  const DataView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DebugViewModel>(context);
    final dataLogs = viewModel.dataLogs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('データログ', style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'ログをクリア',
              onPressed: () {
                viewModel.clearLogs();
              },
            ),
          ],
        ),
        Expanded(
          child: Container(
            color: Colors.grey[200],
            child: ListView.builder(
              controller: ScrollController(), // 常に最新のログが表示されるようにするため、StatelessWidget にしたので ScrollController は不要
              itemCount: dataLogs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
                  child: Text(
                    dataLogs[index],
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}