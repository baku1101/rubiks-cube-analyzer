import 'package:flutter/material.dart';
import '../models/cube_state.dart' as model;

class CubeFaceWidget extends StatelessWidget {
  final List<List<model.Color>> faceState;
  final double size;
  final double borderWidth;

  const CubeFaceWidget({
    Key? key,
    required this.faceState,
    this.size = 120.0,
    this.borderWidth = 2.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cellSize = size / 3;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(
          color: Colors.black,
          width: borderWidth,
        ),
      ),
      child: Column(
        children: List.generate(3, (row) {
          return Row(
            children: List.generate(3, (col) {
              return Container(
                width: cellSize,
                height: cellSize,
                decoration: BoxDecoration(
                  color: _getColorForCubeFace(faceState[row][col]),
                  border: Border.all(
                    color: Colors.black,
                    width: 1.0,
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  // キューブの色情報からMaterialカラーに変換
  MaterialColor _getColorForCubeFace(model.Color cubeColor) {
    switch (cubeColor) {
      case model.Color.white:
        return Colors.grey; // 少し暗めの白に
      case model.Color.yellow:
        return Colors.amber;
      case model.Color.red:
        return Colors.red;
      case model.Color.orange:
        return Colors.deepOrange;
      case model.Color.green:
        return Colors.green;
      case model.Color.blue:
        return Colors.blue;
    }
  }
}