import 'package:shared_preferences/shared_preferences.dart';

class GlobalSettings {
  static final GlobalSettings _instance = GlobalSettings._internal();
  factory GlobalSettings() => _instance;
  GlobalSettings._internal();

  late SharedPreferences prefs;

  Future<void> init(SharedPreferences prefs) async {
    this.prefs = prefs;
  }

  // Define properties with default values directly from the code
  int get defaultContainer =>
      prefs.getInt("defaultContainer") ?? _setInt("defaultContainer", 0);
  int get defaultAudioPort =>
      prefs.getInt("defaultAudioPort") ?? _setInt("defaultAudioPort", 4718);
  bool get autoLaunchVnc =>
      prefs.getBool("autoLaunchVnc") ?? _setBool("autoLaunchVnc", true);
  String get lastDate =>
      prefs.getString("lastDate") ?? _setString("lastDate", "1970-01-01");
  bool get isTerminalWriteEnabled =>
      prefs.getBool("isTerminalWriteEnabled") ??
      _setBool("isTerminalWriteEnabled", false);
  bool get isTerminalCommandsEnabled =>
      prefs.getBool("isTerminalCommandsEnabled") ??
      _setBool("isTerminalCommandsEnabled", false);
  int get termMaxLines =>
      prefs.getInt("termMaxLines") ?? _setInt("termMaxLines", 4095);
  double get termFontScale =>
      prefs.getDouble("termFontScale") ?? _setDouble("termFontScale", 1.0);
  bool get isStickyKey =>
      prefs.getBool("isStickyKey") ?? _setBool("isStickyKey", true);
  bool get reinstallBootstrap =>
      prefs.getBool("reinstallBootstrap") ??
      _setBool("reinstallBootstrap", false);
  bool get getifaddrsBridge =>
      prefs.getBool("getifaddrsBridge") ?? _setBool("getifaddrsBridge", false);
  bool get virgl => prefs.getBool("virgl") ?? _setBool("virgl", false);
  bool get turnip => prefs.getBool("turnip") ?? _setBool("turnip", false);
  bool get dri3 => prefs.getBool("dri3") ?? _setBool("dri3", false);
  bool get wakelock => prefs.getBool("wakelock") ?? _setBool("wakelock", false);
  bool get isHidpiEnabled =>
      prefs.getBool("isHidpiEnabled") ?? _setBool("isHidpiEnabled", false);
  bool get isJpEnabled =>
      prefs.getBool("isJpEnabled") ?? _setBool("isJpEnabled", false);
  bool get useAvnc => prefs.getBool("useAvnc") ?? _setBool("useAvnc", false);
  bool get avncResizeDesktop =>
      prefs.getBool("avncResizeDesktop") ?? _setBool("avncResizeDesktop", true);
  double get avncScaleFactor =>
      (prefs.getDouble("avncScaleFactor") ??
              _setDouble("avncScaleFactor", -0.5))
          .clamp(-1.0, 1.0);
  bool get useX11 => prefs.getBool("useX11") ?? _setBool("useX11", true);
  bool get advancedLogs =>
      prefs.getBool("advancedLogs") ?? _setBool("advancedLogs", false);
  set advancedLogs(bool value) => prefs.setBool("advancedLogs", value);
  // "xfce" or "lxqt" — empty string means not yet chosen (first launch)
  String get selectedDE =>
      prefs.getString("selectedDE") ?? "";
  set selectedDE(String value) => prefs.setString("selectedDE", value);

  String get defaultVirglCommand =>
      prefs.getString("defaultVirglCommand") ??
      _setString(
        "defaultVirglCommand",
        "--use-egl-surfaceless --use-gles --socket-path=\$CONTAINER_DIR/tmp/.virgl_test",
      );
  String get defaultVirglOpt =>
      prefs.getString("defaultVirglOpt") ??
      _setString("defaultVirglOpt", "GALLIUM_DRIVER=virpipe");
  String get defaultTurnipOpt =>
      prefs.getString("defaultTurnipOpt") ??
      _setString(
        "defaultTurnipOpt",
        "MESA_LOADER_DRIVER_OVERRIDE=zink VK_ICD_FILENAMES=/home/tiny/.local/share/tiny/extra/freedreno_icd.aarch64.json TU_DEBUG=noconform",
      );
  String get defaultHidpiOpt =>
      prefs.getString("defaultHidpiOpt") ??
      _setString("defaultHidpiOpt", "GDK_SCALE=2 QT_FONT_DPI=192");
  List<String> get containersInfo =>
      prefs.getStringList("containersInfo") ?? <String>[];

  // Setters
  set isTerminalWriteEnabled(bool value) =>
      prefs.setBool("isTerminalWriteEnabled", value);
  set isTerminalCommandsEnabled(bool value) =>
      prefs.setBool("isTerminalCommandsEnabled", value);
  set isStickyKey(bool value) => prefs.setBool("isStickyKey", value);
  set wakelock(bool value) => prefs.setBool("wakelock", value);
  set getifaddrsBridge(bool value) => prefs.setBool("getifaddrsBridge", value);

  // Helper methods to set and return value
  int _setInt(String key, int value) {
    prefs.setInt(key, value);
    return value;
  }

  bool _setBool(String key, bool value) {
    prefs.setBool(key, value);
    return value;
  }

  double _setDouble(String key, double value) {
    prefs.setDouble(key, value);
    return value;
  }

  String _setString(String key, String value) {
    prefs.setString(key, value);
    return value;
  }

  dynamic getGlobal(String key) {
    switch (key) {
      case "defaultContainer":
        return defaultContainer;
      case "defaultAudioPort":
        return defaultAudioPort;
      case "autoLaunchVnc":
        return autoLaunchVnc;
      case "lastDate":
        return lastDate;
      case "isTerminalWriteEnabled":
        return isTerminalWriteEnabled;
      case "isTerminalCommandsEnabled":
        return isTerminalCommandsEnabled;
      case "termMaxLines":
        return termMaxLines;
      case "termFontScale":
        return termFontScale;
      case "isStickyKey":
        return isStickyKey;
      case "reinstallBootstrap":
        return reinstallBootstrap;
      case "getifaddrsBridge":
        return getifaddrsBridge;
      case "virgl":
        return virgl;
      case "turnip":
        return turnip;
      case "dri3":
        return dri3;
      case "wakelock":
        return wakelock;
      case "isHidpiEnabled":
        return isHidpiEnabled;
      case "isJpEnabled":
        return isJpEnabled;
      case "useAvnc":
        return useAvnc;
      case "avncResizeDesktop":
        return avncResizeDesktop;
      case "avncScaleFactor":
        return avncScaleFactor;
      case "useX11":
        return useX11;
      case "advancedLogs":
        return advancedLogs;
      case "defaultVirglCommand":
        return defaultVirglCommand;
      case "defaultVirglOpt":
        return defaultVirglOpt;
      case "defaultTurnipOpt":
        return defaultTurnipOpt;
      case "defaultHidpiOpt":
        return defaultHidpiOpt;
      case "containersInfo":
        return containersInfo;
      case "selectedDE":
        return selectedDE;
      default:
        return null;
    }
  }
}
