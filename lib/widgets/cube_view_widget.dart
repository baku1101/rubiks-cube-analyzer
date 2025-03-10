import 'package:flutter/material.dart';
import '../models/cube_state.dart' as model;
import 'cube_face_widget.dart';

class CubeViewWidget extends StatelessWidget {
  final model.CubeState cubeState;
  final double faceSize;

  const CubeViewWidget({
    Key? key,
    required this.cubeState,
    this.faceSize = 100.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 上面
          _buildFaceWithLabel('上面 (U)', model.Face.up),
          
          // 中央の行（左、前、右、後）
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFaceWithLabel('左面 (L)', model.Face.left),
                _buildFaceWithLabel('前面 (F)', model.Face.front),
                _buildFaceWithLabel('右面 (R)', model.Face.right),
                _buildFaceWithLabel('後面 (B)', model.Face.back),
              ],
            ),
          ),
          
          // 下面
          _buildFaceWithLabel('下面 (D)', model.Face.down),
        ],
      ),
    );
  }

  // ラベル付きの面ウィジェットを構築
  Widget _buildFaceWithLabel(String label, model.Face face) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          CubeFaceWidget(
            faceState: cubeState.getFace(face),
            size: faceSize,
          ),
        ],
      ),
    );
  }
}