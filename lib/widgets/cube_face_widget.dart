import 'package:flutter/material.dart';
import '../models/cube_state.dart' as cube_model;

class CubeFaceWidget extends StatelessWidget {
  final List<List<Color>> colors;
  final double size;
  final VoidCallback? onTap;

  const CubeFaceWidget({
    super.key,
    required this.colors,
    required this.size,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cellSize = size / 3;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black,
            width: 2,
          ),
        ),
        child: Column(
          children: List.generate(3, (row) {
            return Row(
              children: List.generate(3, (col) {
                return _buildCell(cellSize, colors[row][col]);
              }),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCell(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(
          color: Colors.black,
          width: 1,
        ),
      ),
    );
  }

  // カラーコードを取得
  MaterialColor getMaterialColor(Color color) {
    if (color == cube_model.CubeColor.red) return Colors.red;
    if (color == cube_model.CubeColor.orange) return Colors.orange;
    if (color == cube_model.CubeColor.yellow) return Colors.yellow;
    if (color == cube_model.CubeColor.green) return Colors.green;
    if (color == cube_model.CubeColor.blue) return Colors.blue;
    if (color == cube_model.CubeColor.white) return Colors.grey;
    throw Exception('Unknown color');
  }
}