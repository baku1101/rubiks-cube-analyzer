import 'package:flutter/material.dart';
import '../models/cube_state.dart';
import 'cube_face_widget.dart';

class CubeViewWidget extends StatelessWidget {
  final CubeState cubeState;
  final double size;
  final Map<Face, VoidCallback>? onFaceTap;

  const CubeViewWidget({
    super.key,
    required this.cubeState,
    required this.size,
    this.onFaceTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 4,
      height: size * 3,
      child: Stack(
        children: [
          // 上面（上から2番目、左から2番目）
          Positioned(
            top: size,
            left: size,
            child: CubeFaceWidget(
              colors: cubeState.getFace(Face.up),
              size: size,
              onTap: onFaceTap?[Face.up],
            ),
          ),
          // 左面（上から2番目、左端）
          Positioned(
            top: size,
            left: 0,
            child: CubeFaceWidget(
              colors: cubeState.getFace(Face.left),
              size: size,
              onTap: onFaceTap?[Face.left],
            ),
          ),
          // 前面（上から2番目、左から2番目）
          Positioned(
            top: size,
            left: size,
            child: CubeFaceWidget(
              colors: cubeState.getFace(Face.front),
              size: size,
              onTap: onFaceTap?[Face.front],
            ),
          ),
          // 右面（上から2番目、左から3番目）
          Positioned(
            top: size,
            left: size * 2,
            child: CubeFaceWidget(
              colors: cubeState.getFace(Face.right),
              size: size,
              onTap: onFaceTap?[Face.right],
            ),
          ),
          // 後面（上から2番目、左から4番目）
          Positioned(
            top: size,
            left: size * 3,
            child: CubeFaceWidget(
              colors: cubeState.getFace(Face.back),
              size: size,
              onTap: onFaceTap?[Face.back],
            ),
          ),
          // 下面（一番下、左から2番目）
          Positioned(
            top: size * 2,
            left: size,
            child: CubeFaceWidget(
              colors: cubeState.getFace(Face.down),
              size: size,
              onTap: onFaceTap?[Face.down],
            ),
          ),
        ],
      ),
    );
  }
}