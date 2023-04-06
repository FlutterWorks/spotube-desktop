import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:platform_ui/platform_ui.dart';
import 'package:spotube/components/root/sidebar.dart';
import 'package:spotube/provider/user_preferences_provider.dart';

final colorsMap = {
  "Red": Colors.red,
  "Pink": Colors.pink,
  "Purple": Colors.purple,
  "DeepPurple": Colors.deepPurple,
  "Indigo": Colors.indigo,
  "Blue": Colors.blue,
  "LightBlue": Colors.lightBlue,
  "Cyan": Colors.cyan,
  "Teal": Colors.teal,
  "Green": Colors.green,
  "LightGreen": Colors.lightGreen,
  "Lime": Colors.lime,
  "Yellow": Colors.yellow,
  "Amber": Colors.amber,
  "Orange": Colors.orange,
  "DeepOrange": Colors.deepOrange,
  "Brown": Colors.brown,
};

enum ColorSchemeType {
  accent,
  background,
}

class ColorSchemePickerDialog extends HookConsumerWidget {
  final ColorSchemeType schemeType;
  const ColorSchemePickerDialog({required this.schemeType, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    final preferences = ref.watch(userPreferencesProvider);
    final scheme = preferences.accentColorScheme;
    final active = useState<String>(colorsMap.entries.firstWhere(
      (element) {
        return scheme.value == element.value.value;
      },
    ).key);

    onOk() {
      switch (schemeType) {
        case ColorSchemeType.accent:
          preferences.setAccentColorScheme(colorsMap[active.value]!);
          break;
        default:
          preferences.setBackgroundColorScheme(
            colorsMap[active.value]!,
          );
      }
      Navigator.pop(context);
    }

    return PlatformAlertDialog(
      macosAppIcon: Sidebar.brandLogo(),
      title: Text("Pick ${schemeType.name} color scheme"),
      primaryActions: [
        PlatformBuilder(
          android: (context, data) {
            return PlatformFilledButton(
              onPressed: onOk,
              child: const Text("Save"),
            );
          },
          ios: (context, data) {
            return CupertinoDialogAction(
              onPressed: onOk,
              isDefaultAction: true,
              child: const Text("Save"),
            );
          },
          fallback: PlatformBuilderFallback.android,
        ),
      ],
      secondaryActions: [
        PlatformBuilder(
          fallback: PlatformBuilderFallback.android,
          android: (context, _) {
            return PlatformFilledButton(
              isSecondary: true,
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);
              },
            );
          },
          ios: (context, data) {
            return CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
              },
              isDestructiveAction: true,
              child: const Text("Cancel"),
            );
          },
        ),
      ],
      content: SizedBox(
        height: 200,
        width: 400,
        child: SingleChildScrollView(
          child: Center(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: colorsMap.entries
                  .map(
                    (e) => ColorTile(
                      color: e.value,
                      isActive: active.value == e.key,
                      tooltip: e.key,
                      onPressed: () {
                        active.value = e.key;
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class ColorTile extends StatelessWidget {
  final MaterialColor color;
  final bool isActive;
  final void Function()? onPressed;
  final String? tooltip;
  const ColorTile({
    required this.color,
    this.isActive = false,
    this.onPressed,
    this.tooltip = "",
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            border: isActive
                ? const Border.fromBorderSide(
                    BorderSide(color: Colors.black, width: 5),
                  )
                : null,
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }
}
