import 'package:flutter/material.dart';
import 'package:platform_ui/platform_ui.dart';
import 'package:spotube/extensions/theme.dart';

class ShimmerPlaybuttonCardPainter extends CustomPainter {
  final Color background;
  final Color foreground;
  ShimmerPlaybuttonCardPainter({
    required this.background,
    required this.foreground,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(10),
      ),
      Paint()..color = background,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height - 45),
        const Radius.circular(10),
      ),
      Paint()..color = foreground,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width / 4, size.height - 27, size.width / 2, 10),
        const Radius.circular(10),
      ),
      Paint()..color = foreground,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class ShimmerPlaybuttonCard extends StatelessWidget {
  final int count;

  const ShimmerPlaybuttonCard({
    Key? key,
    this.count = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = PlatformTheme.of(context).brightness == Brightness.dark;
    final shimmerTheme = ShimmerColorTheme(
      shimmerBackgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
      shimmerColor: isDark ? Colors.grey[800] : Colors.grey[300],
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++) ...[
          CustomPaint(
            size: const Size(200, 250),
            painter: ShimmerPlaybuttonCardPainter(
              background: shimmerTheme.shimmerBackgroundColor ??
                  Theme.of(context).scaffoldBackgroundColor,
              foreground:
                  shimmerTheme.shimmerColor ?? Theme.of(context).cardColor,
            ),
          ),
          const SizedBox(width: 10),
        ]
      ],
    );
  }
}

// class ShimmerPlaybuttonCard extends StatelessWidget {
//   final int count;
//   const ShimmerPlaybuttonCard({Key? key, this.count = 4}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final shimmerColor =
//         Theme.of(context).extension<ShimmerColorTheme>()?.shimmerColor ??
//             Colors.white;
//     final shimmerBackgroundColor = Theme.of(context)
//             .extension<ShimmerColorTheme>()
//             ?.shimmerBackgroundColor ??
//         Colors.grey;

//     final card = Stack(
//       children: [
//         SkeletonAnimation(
//           shimmerColor: shimmerColor,
//           borderRadius: BorderRadius.circular(20),
//           shimmerDuration: 1000,
//           child: Container(
//             width: 200,
//             height: 220,
//             decoration: BoxDecoration(
//               color: shimmerBackgroundColor,
//               borderRadius: BorderRadius.circular(10),
//             ),
//             margin: const EdgeInsets.only(top: 10),
//           ),
//         ),
//         Column(
//           children: [
//             SkeletonAnimation(
//               shimmerColor: shimmerBackgroundColor,
//               borderRadius: BorderRadius.circular(20),
//               shimmerDuration: 1000,
//               child: Container(
//                 width: 200,
//                 height: 180,
//                 decoration: BoxDecoration(
//                   color: shimmerColor,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 margin: const EdgeInsets.only(top: 10),
//               ),
//             ),
//             const SizedBox(height: 5),
//             SkeletonAnimation(
//               shimmerColor: shimmerBackgroundColor,
//               borderRadius: BorderRadius.circular(20),
//               shimmerDuration: 1000,
//               child: Container(
//                 width: 150,
//                 height: 10,
//                 decoration: BoxDecoration(
//                   color: shimmerColor,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 margin: const EdgeInsets.only(top: 10),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );

//     return SingleChildScrollView(
//       physics: const NeverScrollableScrollPhysics(),
//       scrollDirection: Axis.horizontal,
//       child: Row(
//         children: [
//           Row(
//             children: List.generate(
//               count,
//               (_) => Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 15),
//                 child: card,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
