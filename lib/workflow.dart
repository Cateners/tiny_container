// workflow.dart  --  This file is part of tiny_computer.

// Copyright (C) 2023 Caten Hu

// Tiny Computer is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License,
// or any later version.

// Tiny Computer is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty
// of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// See the GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see http://www.gnu.org/licenses/.

// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:retry/retry.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:xterm/xterm.dart';
import 'package:flutter_pty/flutter_pty.dart';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:da_ripped_tiny_computer/l10n/app_localizations.dart';

import 'package:avnc_flutter/avnc_flutter.dart';
import 'package:x11_flutter/x11_flutter.dart';

import 'models.dart';
import 'settings.dart';

class Util {
  static Future<void> copyAsset(String src, String dst) async {
    await File(
      dst,
    ).writeAsBytes((await rootBundle.load(src)).buffer.asUint8List());
  }

  static Future<void> copyAsset2(String src, String dst) async {
    ByteData data = await rootBundle.load(src);
    await File(dst).writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }

  static void createDirFromString(String dir) {
    Directory.fromRawPath(
      const Utf8Encoder().convert(dir),
    ).createSync(recursive: true);
  }

  static Future<int> execute(String str) async {
    Pty pty = Pty.start("/system/bin/sh");
    pty.write(const Utf8Encoder().convert("$str\nexit \$?\n"));
    StreamSubscription<Uint8List>? sub;
    if (G.showAdvancedLogs.value) {
      sub = pty.output.listen((data) {
        final text = const Utf8Decoder(allowMalformed: true).convert(data);
        if (text.isEmpty) return;
        final newLines =
            text.split('\n').where((l) => l.isNotEmpty).toList();
        if (newLines.isEmpty) return;
        final updated = [...G.logLines.value, ...newLines];
        // Limit to 500 lines to avoid unbounded memory growth
        G.logLines.value = updated.length > 500
            ? updated.sublist(updated.length - 500)
            : updated;
      });
    }
    try {
      return await pty.exitCode;
    } finally {
      await sub?.cancel();
    }
  }

  // POSIX single-quote escape — safe to embed in any sh -c string.
  // Mirrors ShizukuHelper._escapeArg.
  static String escapeShellArgument(String arg) =>
      "'${arg.replaceAll("'", "'\\''")}'";

  // Fire-and-forget background process (for long-running daemons like
  // virgl_test_server and getifaddrs_bridge_server).
  static void executeBackground(String str) {
    Process.start("/system/bin/sh", ["-c", str]);
  }

  static void termWrite(String str) {
    G.termPtys[G.currentContainer]!.pty.write(
      const Utf8Encoder().convert("$str\n"),
    );
  }

  //所有key
  //int defaultContainer = 0: 默认启动第0个容器
  //int defaultAudioPort = 4718: 默认pulseaudio端口(为了避免和其它软件冲突改成4718了，原默认4713)
  //bool autoLaunchVnc = true: 是否自动启动图形界面并跳转 以前只支持VNC就这么起名了
  //String lastDate: 上次启动软件的日期，yyyy-MM-dd
  //bool isTerminalWriteEnabled = false
  //bool isTerminalCommandsEnabled = false
  //int termMaxLines = 4095 终端最大行数
  //double termFontScale = 1 终端字体大小
  //bool isStickyKey = true 终端ctrl, shift, alt键是否粘滞
  //String defaultFFmpegCommand 默认推流命令
  //String defaultVirglCommand 默认virgl参数
  //String defaultVirglOpt 默认virgl环境变量
  //bool reinstallBootstrap = false 下次启动是否重装引导包
  //bool getifaddrsBridge = false 下次启动是否桥接getifaddrs
  //bool virgl = false 下次启动是否启用virgl
  //bool wakelock = false 屏幕常亮
  //bool isHidpiEnabled = false 是否开启高分辨率
  //bool isJpEnabled = false 是否切换系统到日语
  //bool useAvnc = false 是否默认使用AVNC
  //bool avncResizeDesktop = true 是否默认AVNC按当前屏幕大小调整分辨率
  //double avncScaleFactor = -0.5 AVNC：在当前屏幕大小的基础上调整缩放的比例。范围-1~1，对应比例4^-1~4^1
  //String defaultHidpiOpt 默认HiDPI环境变量
  //? int bootstrapVersion: 启动包版本
  //String[] containersInfo: 所有容器信息(json)
  //{name, boot:"\$DATA_DIR/bin/proot ...", vnc:"startnovnc", vncUrl:"...", commands:[{name:"更新和升级", command:"apt update -y && apt upgrade -y"},
  // bind:[{name:"U盘", src:"/storage/xxxx", dst:"/media/meow"}]...]}
  static dynamic getGlobal(String key) {
    return G.settings.getGlobal(key);
  }

  static dynamic getCurrentProp(String key) {
    String containerJsonStr = getGlobal("containersInfo")[G.currentContainer];
    Map<String, dynamic> jsonMap = jsonDecode(containerJsonStr);
    ContainerInfo info = ContainerInfo.fromJson(jsonMap);

    // Migrate legacy hardcoded VNC password for existing users
    if ((key == "vncUrl" || key == "vncUri" || key == "vncPassword") &&
            !info.hasProp("vncPassword") ||
        (info.hasProp("vncPassword") &&
            info.getProp("vncPassword").toString().isEmpty)) {
      // No stored password yet — generate one and persist it
      String newPass = generateRandomPassword();
      addCurrentProp("vncPassword", newPass);
      info.vncPassword = newPass;
      // Also migrate any existing URLs that have the old password
      if (info.hasProp("vncUrl") &&
          info.getProp("vncUrl").toString().isNotEmpty) {
        String updatedUrl = info.vncUrl.replaceAll(
          "password=12345678",
          "password=$newPass",
        );
        addCurrentProp("vncUrl", updatedUrl);
        info.vncUrl = updatedUrl;
      }
      if (info.hasProp("vncUri") &&
          info.getProp("vncUri").toString().isNotEmpty) {
        String updatedUri = info.vncUri.replaceAll(
          "VncPassword=12345678",
          "VncPassword=$newPass",
        );
        addCurrentProp("vncUri", updatedUri);
        info.vncUri = updatedUri;
      }
    }

    if (info.hasProp(key)) {
      dynamic val = info.getProp(key);
      if (val != null &&
          (val is! String || val.isNotEmpty) &&
          (val is! List || val.isNotEmpty)) {
        return val;
      }
    }

    switch (key) {
      case "name":
        return (value) {
          addCurrentProp(key, value);
          return value;
        }("Debian Trixie");
      case "boot":
        return (value) {
          addCurrentProp(key, value);
          return value;
        }(D.boot);
      case "vnc":
        return (value) {
          addCurrentProp(key, value);
          return value;
        }("start-desktop &");
      case "vncPassword":
        return (value) {
          addCurrentProp(key, value);
          return value;
        }(generateRandomPassword());
      case "vncUrl":
        return (value) {
          addCurrentProp(key, value);
          return value;
        }(
          "http://localhost:36082/vnc.html?host=localhost&port=36082&autoconnect=true&resize=remote&password=${getCurrentProp("vncPassword")}",
        );
      case "vncUri":
        return (value) {
          addCurrentProp(key, value);
          return value;
        }(
          "vnc://127.0.0.1:5904?VncPassword=${getCurrentProp("vncPassword")}&SecurityType=2",
        );
      case "commands":
        return (value) {
          addCurrentProp(key, value);
          return value;
        }(jsonDecode(jsonEncode(D.commands)));
      default:
        return null;
    }
  }

  //用来设置name, boot, vnc, vncUrl等
  static Future<void> setCurrentProp(String key, dynamic value) async {
    List<String> containersInfo = List<String>.from(
      getGlobal("containersInfo"),
    );
    ContainerInfo info = ContainerInfo.fromJson(
      jsonDecode(containersInfo[G.currentContainer]),
    );

    info.setProp(key, value);

    containersInfo[G.currentContainer] = jsonEncode(info.toJson());
    await G.prefs.setStringList("containersInfo", containersInfo);
  }

  //用来添加不存在的key等
  static Future<void> addCurrentProp(String key, dynamic value) async {
    List<String> containersInfo = List<String>.from(
      getGlobal("containersInfo"),
    );
    ContainerInfo info = ContainerInfo.fromJson(
      jsonDecode(containersInfo[G.currentContainer]),
    );

    info.setProp(key, value);

    containersInfo[G.currentContainer] = jsonEncode(info.toJson());
    await G.prefs.setStringList("containersInfo", containersInfo);
  }

  //限定字符串在min和max之间, 给文本框的validator
  static String? validateBetween(
    String? value,
    int min,
    int max,
    Function opr,
  ) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(G.homePageStateContext)!.enterNumber;
    }
    int? parsedValue = int.tryParse(value);
    if (parsedValue == null) {
      return AppLocalizations.of(G.homePageStateContext)!.enterValidNumber;
    }
    if (parsedValue < min || parsedValue > max) {
      return AppLocalizations.of(
        G.homePageStateContext,
      )!.enterNumberBetween(min, max);
    }
    opr();
    return null;
  }

  static Future<bool> isXServerReady(
    String host,
    int port, {
    int timeoutSeconds = 5,
    Future<Socket> Function(dynamic host, int port, {Duration? timeout})?
    connectSocket,
  }) async {
    final connect = connectSocket ?? Socket.connect;
    try {
      final socket = await connect(
        host,
        port,
        timeout: Duration(seconds: timeoutSeconds),
      );
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> waitForXServer({
    int timeoutSeconds = 60,
    Future<bool> Function(String host, int port) isReadyCheck = isXServerReady,
  }) async {
    const host = '127.0.0.1';
    const port = 7897;
    final deadline = DateTime.now().add(Duration(seconds: timeoutSeconds));

    while (DateTime.now().isBefore(deadline)) {
      if (await isReadyCheck(host, port)) {
        return;
      }
      await Future.delayed(const Duration(seconds: 1));
    }
    throw TimeoutException(
      'X server did not start within $timeoutSeconds seconds',
    );
  }

  static String getl10nText(String key, BuildContext context) {
    switch (key) {
      case 'projectUrl':
        return AppLocalizations.of(context)!.projectUrl;
      case 'issueUrl':
        return AppLocalizations.of(context)!.issueUrl;
      case 'faqUrl':
        return AppLocalizations.of(context)!.faqUrl;
      case 'solutionUrl':
        return AppLocalizations.of(context)!.solutionUrl;
      case 'discussionUrl':
        return AppLocalizations.of(context)!.discussionUrl;
      default:
        return AppLocalizations.of(context)!.projectUrl;
    }
  }

  static String generateRandomPassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(8, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }
}

//来自xterms关于操作ctrl, shift, alt键的示例
//这个类应该只能有一个实例G.keyboard
class VirtualKeyboard extends TerminalInputHandler with ChangeNotifier {
  final TerminalInputHandler _inputHandler;

  VirtualKeyboard(this._inputHandler);

  bool _ctrl = false;

  bool get ctrl => _ctrl;

  set ctrl(bool value) {
    if (_ctrl != value) {
      _ctrl = value;
      notifyListeners();
    }
  }

  bool _shift = false;

  bool get shift => _shift;

  set shift(bool value) {
    if (_shift != value) {
      _shift = value;
      notifyListeners();
    }
  }

  bool _alt = false;

  bool get alt => _alt;

  set alt(bool value) {
    if (_alt != value) {
      _alt = value;
      notifyListeners();
    }
  }

  @override
  String? call(TerminalKeyboardEvent event) {
    final ret = _inputHandler.call(
      event.copyWith(
        ctrl: event.ctrl || _ctrl,
        shift: event.shift || _shift,
        alt: event.alt || _alt,
      ),
    );
    G.maybeCtrlJ = event.key.name == "keyJ"; //这个是为了稍后区分按键到底是Enter还是Ctrl+J
    if (!(Util.getGlobal("isStickyKey") as bool)) {
      G.keyboard.ctrl = false;
      G.keyboard.shift = false;
      G.keyboard.alt = false;
    }
    return ret;
  }
}

//一个结合terminal和pty的类
class TermPty {
  late final Terminal terminal;
  late final Pty pty;

  TermPty() {
    terminal = Terminal(
      inputHandler: G.keyboard,
      maxLines: Util.getGlobal("termMaxLines") as int,
    );
    pty = Pty.start(
      "/system/bin/sh",
      workingDirectory: G.dataPath,
      columns: terminal.viewWidth,
      rows: terminal.viewHeight,
    );
    pty.output
        .cast<List<int>>()
        .transform(const Utf8Decoder())
        .listen(terminal.write);
    pty.exitCode.then((code) {
      terminal.write('the process exited with exit code $code');
      if (code == 0) {
        SystemChannels.platform.invokeMethod("SystemNavigator.pop");
      }
      //Signal 9 hint
      if (code == -9) {
        D.androidChannel.invokeMethod("launchSignal9Page", {});
      }
    });
    terminal.onOutput = (data) {
      if (!(Util.getGlobal("isTerminalWriteEnabled") as bool)) {
        return;
      }
      //由于对回车的处理似乎存在问题，所以拿出来单独处理
      data.split("").forEach((element) {
        if (element == "\n" && !G.maybeCtrlJ) {
          terminal.keyInput(TerminalKey.enter);
          return;
        }
        G.maybeCtrlJ = false;
        pty.write(const Utf8Encoder().convert(element));
      });
    };
    terminal.onResize = (w, h, pw, ph) {
      pty.resize(h, w);
    };
  }
}

//default values
class D {
  //常用链接
  static const links = [
    {
      "name": "projectUrl",
      "value": "https://github.com/Cateners/tiny_computer",
    },
    {
      "name": "issueUrl",
      "value": "https://github.com/Cateners/tiny_computer/issues",
    },
    {
      "name": "faqUrl",
      "value": "https://gitee.com/caten/tc-hints/blob/master/pool/faq.md",
    },
    {
      "name": "solutionUrl",
      "value": "https://gitee.com/caten/tc-hints/blob/master/pool/solution.md",
    },
    {
      "name": "discussionUrl",
      "value": "https://github.com/Cateners/tiny_computer/discussions",
    },
  ];

  //默认快捷指令
  static const commands = [
    {
      "name": "检查更新并升级",
      "command": "sudo pacman -Syu --noconfirm && sudo pacman -Sc --noconfirm",
    },
    {"name": "查看系统信息", "command": "neofetch -L && neofetch --off"},
    {"name": "清屏", "command": "clear"},
    {"name": "中断任务", "command": "\x03"},
    {"name": "安装图形处理软件Krita", "command": "sudo pacman -S --noconfirm krita"},
    {"name": "卸载Krita", "command": "sudo pacman -Rns --noconfirm krita"},
    {
      "name": "安装视频剪辑软件Kdenlive",
      "command": "sudo pacman -S --noconfirm kdenlive",
    },
    {"name": "卸载Kdenlive", "command": "sudo pacman -Rns --noconfirm kdenlive"},
    {"name": "安装科学计算软件Octave", "command": "sudo pacman -S --noconfirm octave"},
    {"name": "卸载Octave", "command": "sudo pacman -Rns --noconfirm octave"},
    {
      "name": "安装WPS",
      "command":
          r"""cat << 'EOF' | sh && sudo pacman -U --noconfirm /tmp/wps.deb
wget https://mirrors.sdu.edu.cn/spark-store/arm64-store/office/wps-office/wps-office_11.1.0.11720-fix3_arm64.deb -O /tmp/wps.deb
EOF
rm /tmp/wps.deb""",
    },
    {"name": "卸载WPS", "command": "sudo pacman -Rns --noconfirm wps-office"},
    {
      "name": "安装CAJViewer",
      "command":
          "wget https://download.cnki.net/cajPackage/tongxinUOS/signed_cajviewer_9.5.0-25268_arm64.deb -O /tmp/caj.deb && sudo pacman -U --noconfirm /tmp/caj.deb; rm /tmp/caj.deb",
    },
    {
      "name": "卸载CAJViewer",
      "command": "sudo pacman -Rns --noconfirm cajviewer",
    },
    {
      "name": "安装亿图图示",
      "command":
          "wget https://cc-download.wondershare.cc/business/prd/edrawmax_13.1.0-1_arm64_binner.deb -O /tmp/edraw.deb && sudo pacman -U --noconfirm /tmp/edraw.deb && bash /home/tiny/.local/share/tiny/edraw/postinst; rm /tmp/edraw.deb",
    },
    {
      "name": "卸载亿图图示",
      "command": "sudo pacman -Rns --noconfirm edrawmax libldap-2.4-2",
    },
    {
      "name": "安装QQ",
      "command":
          """wget \$(curl -s https://cdn-go.cn/qq-web/im.qq.com_new/latest/rainbow/linuxConfig.js | grep -oP '"armDownloadUrl":{[^}]*"deb":"\\K[^"]+') -O /tmp/qq.deb && sudo pacman -U --noconfirm /tmp/qq.deb && sed -i 's#Exec=/opt/QQ/qq %U#Exec=/opt/QQ/qq --no-sandbox %U#g' /usr/share/applications/qq.desktop; rm /tmp/qq.deb""",
    },
    {"name": "卸载QQ", "command": "sudo pacman -Rns --noconfirm linuxqq"},
    {
      "name": "安装微信",
      "command":
          "wget https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_arm64.deb -O /tmp/wechat.deb && sudo pacman -U --noconfirm /tmp/wechat.deb && echo '安装完成。如果你使用微信只是为了传输文件，那么可以考虑使用支持SAF的文件管理器（如：质感文件），直接访问小小电脑所有文件。'; rm /tmp/wechat.deb",
    },
    {"name": "卸载微信", "command": "sudo pacman -Rns --noconfirm wechat"},
    {
      "name": "安装钉钉",
      "command":
          """wget \$(curl -sw %{redirect_url} https://www.dingtalk.com/win/d/qd=linux_arm64) -O /tmp/dingtalk.deb && sudo pacman -U --noconfirm /tmp/dingtalk.deb libglut3.12 libglu1-mesa && sed -i 's#\\./com.alibabainc.dingtalk#\\./com.alibabainc.dingtalk --no-sandbox#g' /opt/apps/com.alibabainc.dingtalk/files/Elevator.sh; rm /tmp/dingtalk.deb""",
    },
    {
      "name": "卸载钉钉",
      "command": "sudo pacman -Rns --noconfirm com.alibabainc.dingtalk",
    },
    {
      "name": "启用回收站",
      "command": "sudo pacman -S --noconfirm gvfs && echo '安装完成, 重启软件即可使用回收站。'",
    },
    {"name": "清理包管理器缓存", "command": "sudo pacman -Scc --noconfirm"},
    {"name": "关机", "command": "stopvnc\nexit\nexit"},
    {"name": "???", "command": "timeout 8 cmatrix"},
  ];

  //默认快捷指令，英文版本
  static const commands4En = [
    {
      "name": "Update Packages",
      "command": "sudo pacman -Syu --noconfirm && sudo pacman -Sc --noconfirm",
    },
    {"name": "System Info", "command": "neofetch -L && neofetch --off"},
    {"name": "Clear", "command": "clear"},
    {"name": "Interrupt", "command": "\x03"},
    {
      "name": "Install Painting Program Krita",
      "command": "sudo pacman -S --noconfirm krita",
    },
    {
      "name": "Uninstall Krita",
      "command": "sudo pacman -Rns --noconfirm krita",
    },
    {
      "name": "Install KDE Non-Linear Video Editor",
      "command": "sudo pacman -S --noconfirm kdenlive",
    },
    {
      "name": "Uninstall Kdenlive",
      "command": "sudo pacman -Rns --noconfirm kdenlive",
    },
    {
      "name": "Install LibreOffice",
      "command": "sudo pacman -S --noconfirm libreoffice",
    },
    {
      "name": "Uninstall LibreOffice",
      "command": "sudo pacman -Rns --noconfirm libreoffice",
    },
    {
      "name": "Install WPS",
      "command":
          r"""cat << 'EOF' | sh && sudo pacman -U --noconfirm /tmp/wps.deb
wget https://github.com/tiny-computer/third-party-archives/releases/download/archives/wps-office_11.1.0.11720_arm64.deb -O /tmp/wps.deb
EOF
rm /tmp/wps.deb""",
    },
    {
      "name": "Uninstall WPS",
      "command": "sudo pacman -Rns --noconfirm wps-office",
    },
    {
      "name": "Install EdrawMax",
      "command":
          """wget https://cc-download.wondershare.cc/business/prd/edrawmax_13.1.0-1_arm64_binner.deb -O /tmp/edraw.deb && sudo pacman -U --noconfirm /tmp/edraw.deb && bash /home/tiny/.local/share/tiny/edraw/postinst && sudo sed -i 's/<Language V="cn"\\/>/<Language V="en"\\/>/g' /opt/apps/edrawmax/config/settings.xml; rm /tmp/edraw.deb""",
    },
    {
      "name": "Uninstall EdrawMax",
      "command": "sudo pacman -Rns --noconfirm edrawmax",
    },
    {
      "name": "Enable Recycle Bin",
      "command":
          "sudo pacman -S --noconfirm gvfs && echo 'Restart the app to use Recycle Bin.'",
    },
    {"name": "Clean Package Cache", "command": "sudo pacman -Scc --noconfirm"},
    {"name": "Power Off", "command": "stopvnc\nexit\nexit"},
    {"name": "???", "command": "timeout 8 cmatrix"},
  ];

  //默认wine快捷指令
  static const wineCommands = [
    {"name": "Wine配置", "command": "winecfg"},
    {
      "name": "修复方块字",
      "command":
          "regedit Z:\\\\home\\\\tiny\\\\.local\\\\share\\\\tiny\\\\extra\\\\chn_fonts.reg && wine reg delete \"HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows NT\\CurrentVersion\\FontSubstitutes\" /va /f",
    },
    {
      "name": "开始菜单文件夹",
      "command":
          "wine explorer \"C:\\\\ProgramData\\\\Microsoft\\\\Windows\\\\Start Menu\\\\Programs\"",
    },
    {
      "name": "开启DXVK",
      "command":
          """WINEDLLOVERRIDES="d3d8=n,d3d9=n,d3d10core=n,d3d11=n,dxgi=n" wine reg add 'HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides' /v d3d8 /d native /f >/dev/null 2>&1
WINEDLLOVERRIDES="d3d8=n,d3d9=n,d3d10core=n,d3d11=n,dxgi=n" wine reg add 'HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides' /v d3d9 /d native /f >/dev/null 2>&1
WINEDLLOVERRIDES="d3d8=n,d3d9=n,d3d10core=n,d3d11=n,dxgi=n" wine reg add 'HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides' /v d3d10core /d native /f >/dev/null 2>&1
WINEDLLOVERRIDES="d3d8=n,d3d9=n,d3d10core=n,d3d11=n,dxgi=n" wine reg add 'HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides' /v d3d11 /d native /f >/dev/null 2>&1
WINEDLLOVERRIDES="d3d8=n,d3d9=n,d3d10core=n,d3d11=n,dxgi=n" wine reg add 'HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides' /v dxgi /d native /f >/dev/null 2>&1""",
    },
    {
      "name": "关闭DXVK",
      "command":
          """WINEDLLOVERRIDES="d3d8=b,d3d9=b,d3d10core=b,d3d11=b,dxgi=b" wine reg add 'HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides' /v d3d8 /d builtin /f >/dev/null 2>&1
WINEDLLOVERRIDES="d3d8=b,d3d9=b,d3d10core=b,d3d11=b,dxgi=b" wine reg add 'HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides' /v d3d9 /d builtin /f >/dev/null 2>&1
WINEDLLOVERRIDES="d3d8=b,d3d9=b,d3d10core=b,d3d11=b,dxgi=b" wine reg add 'HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides' /v d3d10core /d builtin /f >/dev/null 2>&1
WINEDLLOVERRIDES="d3d8=b,d3d9=b,d3d10core=b,d3d11=b,dxgi=b" wine reg add 'HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides' /v d3d11 /d builtin /f >/dev/null 2>&1
WINEDLLOVERRIDES="d3d8=b,d3d9=b,d3d10core=b,d3d11=b,dxgi=b" wine reg add 'HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides' /v dxgi /d builtin /f >/dev/null 2>&1""",
    },
    {"name": "我的电脑", "command": "wine explorer"},
    {"name": "记事本", "command": "notepad"},
    {"name": "扫雷", "command": "winemine"},
    {"name": "注册表", "command": "regedit"},
    {"name": "控制面板", "command": "wine control"},
    {"name": "文件管理器", "command": "winefile"},
    {"name": "任务管理器", "command": "wine taskmgr"},
    {"name": "IE浏览器", "command": "wine iexplore"},
    {"name": "强制关闭Wine", "command": "wineserver -k"},
  ];

  //默认wine快捷指令，英文版本
  static const wineCommands4En = [
    {"name": "Wine Configuration", "command": "winecfg"},
    {
      "name": "Fix CJK Characters",
      "command":
          "regedit Z:\\\\home\\\\tiny\\\\.local\\\\share\\\\tiny\\\\extra\\\\chn_fonts.reg && wine reg delete \"HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows NT\\CurrentVersion\\FontSubstitutes\" /va /f",
    },
    {
      "name": "Start Menu Dir",
      "command":
          "wine explorer \"C:\\\\ProgramData\\\\Microsoft\\\\Windows\\\\Start Menu\\\\Programs\"",
    },
    {
      "name": "Enable DXVK",
      "command":
          """WINEDLLOVERRIDES="d3d8=n,d3d9=n,d3d10core=n,d3d11=n,dxgi=n" wine reg add 'HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides' /v d3d8 /d native /f >/dev/null 2>&1
WINEDLLOVERRIDES="d3d8=n,d3d9=n,d3d10core=n,d3d11=n,dxgi=n" wine reg add 'HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides' /v d3d9 /d native /f >/dev/null 2>&1
WINEDLLOVERRIDES="d3d8=n,d3d9=n,d3d10core=n,d3d11=n,dxgi=n" wine reg add 'HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides' /v d3d10core /d native /f >/dev/null 2>&1
WINEDLLOVERRIDES="d3d8=n,d3d9=n,d3d10core=n,d3d11=n,dxgi=n" wine reg add 'HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides' /v d3d11 /d native /f >/dev/null 2>&1
WINEDLLOVERRIDES="d3d8=n,d3d9=n,d3d10core=n,d3d11=n,dxgi=n" wine reg add 'HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides' /v dxgi /d native /f >/dev/null 2>&1""",
    },
    {
      "name": "Disable DXVK",
      "command":
          """WINEDLLOVERRIDES="d3d8=b,d3d9=b,d3d10core=b,d3d11=b,dxgi=b" wine reg add 'HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides' /v d3d8 /d builtin /f >/dev/null 2>&1
WINEDLLOVERRIDES="d3d8=b,d3d9=b,d3d10core=b,d3d11=b,dxgi=b" wine reg add 'HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides' /v d3d9 /d builtin /f >/dev/null 2>&1
WINEDLLOVERRIDES="d3d8=b,d3d9=b,d3d10core=b,d3d11=b,dxgi=b" wine reg add 'HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides' /v d3d10core /d builtin /f >/dev/null 2>&1
WINEDLLOVERRIDES="d3d8=b,d3d9=b,d3d10core=b,d3d11=b,dxgi=b" wine reg add 'HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides' /v d3d11 /d builtin /f >/dev/null 2>&1
WINEDLLOVERRIDES="d3d8=b,d3d9=b,d3d10core=b,d3d11=b,dxgi=b" wine reg add 'HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides' /v dxgi /d builtin /f >/dev/null 2>&1""",
    },
    {"name": "Explorer", "command": "wine explorer"},
    {"name": "Notepad", "command": "notepad"},
    {"name": "Minesweeper", "command": "winemine"},
    {"name": "Regedit", "command": "regedit"},
    {"name": "Control Panel", "command": "wine control"},
    {"name": "File Manager", "command": "winefile"},
    {"name": "Task Manager", "command": "wine taskmgr"},
    {"name": "Internet Explorer", "command": "wine iexplore"},
    {"name": "Kill Wine Process", "command": "wineserver -k"},
  ];

  //默认小键盘
  static const termCommands = [
    {"name": "Esc", "key": TerminalKey.escape},
    {"name": "Tab", "key": TerminalKey.tab},
    {"name": "↑", "key": TerminalKey.arrowUp},
    {"name": "↓", "key": TerminalKey.arrowDown},
    {"name": "←", "key": TerminalKey.arrowLeft},
    {"name": "→", "key": TerminalKey.arrowRight},
    {"name": "Del", "key": TerminalKey.delete},
    {"name": "PgUp", "key": TerminalKey.pageUp},
    {"name": "PgDn", "key": TerminalKey.pageDown},
    {"name": "Home", "key": TerminalKey.home},
    {"name": "End", "key": TerminalKey.end},
    {"name": "F1", "key": TerminalKey.f1},
    {"name": "F2", "key": TerminalKey.f2},
    {"name": "F3", "key": TerminalKey.f3},
    {"name": "F4", "key": TerminalKey.f4},
    {"name": "F5", "key": TerminalKey.f5},
    {"name": "F6", "key": TerminalKey.f6},
    {"name": "F7", "key": TerminalKey.f7},
    {"name": "F8", "key": TerminalKey.f8},
    {"name": "F9", "key": TerminalKey.f9},
    {"name": "F10", "key": TerminalKey.f10},
    {"name": "F11", "key": TerminalKey.f11},
    {"name": "F12", "key": TerminalKey.f12},
  ];

  static const String boot =
      "PROOT_NO_SECCOMP=1 \$DATA_DIR/bin/proot -H --change-id=1000:1000 --pwd=/home/tiny --rootfs=\$CONTAINER_DIR --mount=/system --mount=/apex --mount=/sys --mount=/data --kill-on-exit --mount=/storage --sysvipc -L --link2symlink --mount=/proc --mount=/dev --mount=/data/data/com.termux/files/usr/tmp:/tmp --mount=\$CONTAINER_DIR/tmp:/dev/shm --mount=/dev/urandom:/dev/random --mount=/proc/self/fd:/dev/fd --mount=/proc/self/fd/0:/dev/stdin --mount=/proc/self/fd/1:/dev/stdout --mount=/proc/self/fd/2:/dev/stderr --mount=/dev/null:/dev/tty0 --mount=/storage/self/primary:/media/sd --mount=\$DATA_DIR/share:/home/tiny/Public --mount=\$DATA_DIR/tiny:/home/tiny/.local/share/tiny --mount=/storage/self/primary/Fonts:/usr/share/fonts/wpsm --mount=/storage/self/primary/AppFiles/Fonts:/usr/share/fonts/yozom --mount=/system/fonts:/usr/share/fonts/androidm --mount=/storage/self/primary/Pictures:/home/tiny/Pictures --mount=/storage/self/primary/Music:/home/tiny/Music --mount=/storage/self/primary/Movies:/home/tiny/Videos --mount=/storage/self/primary/Download:/home/tiny/Downloads --mount=/storage/self/primary/DCIM:/home/tiny/Photos --mount=/storage/self/primary/Documents:/home/tiny/Documents \$EXTRA_MOUNT /usr/bin/env -i HOME=/home/tiny USER=tiny LANG=en_US.UTF-8 TERM=xterm-256color PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin PULSE_SERVER=tcp:127.0.0.1:4718 DISPLAY=:4 \$EXTRA_OPT /bin/bash /usr/local/bin/start-arch.sh";

  static final ButtonStyle commandButtonStyle = OutlinedButton.styleFrom(
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    minimumSize: const Size(0, 0),
    padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
  );

  static final ButtonStyle controlButtonStyle = OutlinedButton.styleFrom(
    textStyle: const TextStyle(fontWeight: FontWeight.w400),
    side: const BorderSide(color: Color(0x1F000000)),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    minimumSize: const Size(0, 0),
    padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
  );

  static const MethodChannel androidChannel = MethodChannel("android");
}

// Global variables
class G {
  static late final String dataPath;
  static Pty? audioPty;
  static late WebViewController controller;
  static late BuildContext homePageStateContext;
  static late int currentContainer; //目前运行第几个容器
  static late Map<int, TermPty> termPtys; //为容器<int>存放TermPty数据
  static late VirtualKeyboard keyboard; //存储ctrl, shift, alt状态
  static bool maybeCtrlJ = false; //为了区分按下的ctrl+J和enter而准备的变量
  static ValueNotifier<double> termFontScale = ValueNotifier(
    1,
  ); //终端字体大小，存储为G.prefs的termFontScale
  static bool isStreaming = false;
  //static int? virglPid;
  static ValueNotifier<int> pageIndex = ValueNotifier(0); //主界面索引
  static ValueNotifier<bool> terminalPageChange = ValueNotifier(
    true,
  ); //更改值，用于刷新小键盘
  static ValueNotifier<bool> bootTextChange = ValueNotifier(
    true,
  ); //更改值，用于刷新启动命令
  static ValueNotifier<String> updateText = ValueNotifier("小小电脑"); //加载界面的说明文字
  static ValueNotifier<bool> showAdvancedLogs = ValueNotifier(false); // Whether to show the log console
  static ValueNotifier<List<String>> logLines = ValueNotifier([]); // Captured PTY output lines
  static String postCommand = ""; //第一次进入容器时额外运行的命令

  static bool wasAvncEnabled = false;
  static bool wasX11Enabled = false;

  static late SharedPreferences prefs;
  static late GlobalSettings settings;
}

class Workflow {
  // Validates that a VNC password contains only alphanumeric characters, as
  // generated by Util.generateRandomPassword(). If a stored value was tampered
  // with and contains shell metacharacters, returns a fresh safe password
  // instead of allowing injection into the sed command that patches start-vnc.
  static String _sanitizeVncPassword(String password) {
    if (RegExp(r'^[a-zA-Z0-9]+$').hasMatch(password)) return password;
    return Util.generateRandomPassword();
  }

  static Future<bool> grantPermissions() async {
    final status = await Permission.storage.request();
    return status.isGranted || status.isLimited;
    //Permission.manageExternalStorage.request();
  }

  // Shows a full-screen DE selection dialog on first launch.
  // Returns "xfce" or "lxqt".
  static Future<String> _showDeSelectionDialog() async {
    final completer = Completer<String>();
    final l10n = AppLocalizations.of(G.homePageStateContext)!;
    showDialog<void>(
      context: G.homePageStateContext,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.chooseDesktop),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.chooseDesktopDesc),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _DeCard(
                      name: l10n.desktopXfce,
                      description: l10n.desktopXfceDesc,
                      buttonLabel: l10n.selectThisDesktop,
                      onTap: () {
                        Navigator.of(context).pop();
                        completer.complete('xfce');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DeCard(
                      name: l10n.desktopLxqt,
                      description: l10n.desktopLxqtDesc,
                      buttonLabel: l10n.selectThisDesktop,
                      onTap: () {
                        Navigator.of(context).pop();
                        completer.complete('lxqt');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    return completer.future;
  }

  static Future<void> setupBootstrap() async {
    //用来共享数据文件的文件夹
    Util.createDirFromString("${G.dataPath}/share");
    //用来存放可执行文件的文件夹
    Util.createDirFromString("${G.dataPath}/bin");
    //用来存放库的文件夹
    Util.createDirFromString("${G.dataPath}/lib");
    //挂载到/dev/shm的文件夹
    Util.createDirFromString("${G.dataPath}/tmp");
    //给proot的tmp文件夹，虽然我不知道为什么proot要这个
    Util.createDirFromString("${G.dataPath}/proot_tmp");
    //给pulseaudio的tmp文件夹
    Util.createDirFromString("${G.dataPath}/pulseaudio_tmp");
    //解压后得到bin文件夹和libexec文件夹
    //bin存放了proot, pulseaudio, tar等
    //libexec存放了proot loader
    await Util.copyAsset("assets/assets.zip", "${G.dataPath}/assets.zip");
    //patch.tar.gz存放了tiny文件夹
    //里面是一些补丁，会被挂载到~/.local/share/tiny
    await Util.copyAsset("assets/patch.tar.gz", "${G.dataPath}/patch.tar.gz");
    await Util.execute("""
export DATA_DIR=${G.dataPath}
export LD_LIBRARY_PATH=\$DATA_DIR/lib
cd \$DATA_DIR
ln -sf ../applib/libexec_busybox.so \$DATA_DIR/bin/busybox
ln -sf ../applib/libexec_busybox.so \$DATA_DIR/bin/sh
ln -sf ../applib/libexec_busybox.so \$DATA_DIR/bin/cat
ln -sf ../applib/libexec_busybox.so \$DATA_DIR/bin/xz
ln -sf ../applib/libexec_busybox.so \$DATA_DIR/bin/gzip
ln -sf ../applib/libexec_proot.so \$DATA_DIR/bin/proot
ln -sf ../applib/libexec_tar.so \$DATA_DIR/bin/tar
ln -sf ../applib/libexec_virgl_test_server.so \$DATA_DIR/bin/virgl_test_server
ln -sf ../applib/libexec_getifaddrs_bridge_server.so \$DATA_DIR/bin/getifaddrs_bridge_server
ln -sf ../applib/libexec_pulseaudio.so \$DATA_DIR/bin/pulseaudio
ln -sf ../applib/libacl.so \$DATA_DIR/lib/libacl.so
ln -sf ../applib/libandroid-selinux.so \$DATA_DIR/lib/libandroid-selinux.so
ln -sf ../applib/libattr.so \$DATA_DIR/lib/libattr.so
ln -sf ../applib/libbusybox.so \$DATA_DIR/lib/libbusybox.so.1.37.0
ln -sf ../applib/libiconv.so \$DATA_DIR/lib/libiconv.so
ln -sf ../applib/libpcre2-8.so \$DATA_DIR/lib/libpcre2-8.so
ln -sf ../applib/libtalloc.so \$DATA_DIR/lib/libtalloc.so.2
ln -sf ../applib/libvirglrenderer.so \$DATA_DIR/lib/libvirglrenderer.so
ln -sf ../applib/libepoxy.so \$DATA_DIR/lib/libepoxy.so
ln -sf ../applib/libproot-loader32.so \$DATA_DIR/lib/loader32
ln -sf ../applib/libproot-loader.so \$DATA_DIR/lib/loader

\$DATA_DIR/bin/busybox unzip -o assets.zip
chmod -R +x bin/*
chmod -R +x libexec/proot/*
chmod 1777 tmp
\$DATA_DIR/bin/tar zxf patch.tar.gz
\$DATA_DIR/bin/busybox rm -rf assets.zip patch.tar.gz
""");
  }

  //初次启动要做的事情
  static Future<void> initForFirstTime() async {
    // Clear log lines before starting so the log view shows only current session.
    G.logLines.value = [];
    //首先设置bootstrap
    G.updateText.value = AppLocalizations.of(
      G.homePageStateContext,
    )!.installingBootPackage;
    await setupBootstrap();

          // ignore: use_build_context_synchronously
    // ignore: use_build_context_synchronously
    G.updateText.value = AppLocalizations.of(
      G.homePageStateContext,
    )!.copyingContainerSystem;
    //存放容器的文件夹0和存放硬链接的文件夹.l2s
    Util.createDirFromString("${G.dataPath}/containers/0/.l2s");
    //这个是容器rootfs，被split命令分成了xa*，放在assets里
    //首次启动，就用这个，别让用户另选了
    //使用 AssetManifest API 获取 assets/xa* 文件列表
    final AssetManifest manifest = await AssetManifest.loadFromAssetBundle(
      rootBundle,
    );
    final List<String> xaFiles = manifest
        .listAssets()
        .where((String key) => key.startsWith('assets/xa'))
        .map((String key) => key.split('/').last)
        .toList();
    await Future.wait(
      xaFiles.map(
        (String name) => Util.copyAsset("assets/$name", "${G.dataPath}/$name"),
      ),
    );
    //-J
    // ignore: use_build_context_synchronously
    G.updateText.value = AppLocalizations.of(
      G.homePageStateContext,
    )!.installingContainerSystem;
    await Util.execute("""
export DATA_DIR=${G.dataPath}
export PATH=\$DATA_DIR/bin:\$PATH
export LD_LIBRARY_PATH=\$DATA_DIR/lib
export CONTAINER_DIR=\$DATA_DIR/containers/0
export EXTRA_OPT=""
cd \$DATA_DIR
export PATH=\$DATA_DIR/bin:\$PATH
export PROOT_TMP_DIR=\$DATA_DIR/proot_tmp
export PROOT_LOADER=\$DATA_DIR/applib/libproot-loader.so
export PROOT_LOADER_32=\$DATA_DIR/applib/libproot-loader32.so
#export PROOT_L2S_DIR=\$CONTAINER_DIR/.l2s
\$DATA_DIR/bin/proot --link2symlink sh -c "cat xa* | \$DATA_DIR/bin/tar x -z --delay-directory-restore --preserve-permissions -v -C containers/0"
#Script from proot-distro
chmod u+rw "\$CONTAINER_DIR/etc/passwd" "\$CONTAINER_DIR/etc/shadow" "\$CONTAINER_DIR/etc/group" "\$CONTAINER_DIR/etc/gshadow"
echo "aid_\$(id -un):x:\$(id -u):\$(id -g):Termux:/:/sbin/nologin" >> "\$CONTAINER_DIR/etc/passwd"
echo "aid_\$(id -un):*:18446:0:99999:7:::" >> "\$CONTAINER_DIR/etc/shadow"
id -Gn | tr ' ' '\\n' > tmp1
id -G | tr ' ' '\\n' > tmp2
\$DATA_DIR/bin/busybox paste tmp1 tmp2 > tmp3
local group_name group_id
cat tmp3 | while read -r group_name group_id; do
	echo "aid_\${group_name}:x:\${group_id}:root,aid_\$(id -un)" >> "\$CONTAINER_DIR/etc/group"
	if [ -f "\$CONTAINER_DIR/etc/gshadow" ]; then
		echo "aid_\${group_name}:*::root,aid_\$(id -un)" >> "\$CONTAINER_DIR/etc/gshadow"
	fi
done
\$DATA_DIR/bin/busybox rm -rf xa* tmp1 tmp2 tmp3
""");
    //一些数据初始化
    //$DATA_DIR是数据文件夹, $CONTAINER_DIR是容器根目录
    //Termux:X11的启动命令并不在这里面，而是写死了。这下成💩山代码了:P
    String initialVncPassword = Util.generateRandomPassword();
    // ignore: use_build_context_synchronously
    await G.prefs.setStringList("containersInfo", [
      """{
"name":"Arch Linux",
"boot":"${D.boot}",
"vnc":"start-desktop &",
"vncPassword":"$initialVncPassword",
"vncUrl":"http://localhost:36082/vnc.html?host=localhost&port=36082&autoconnect=true&resize=remote&password=$initialVncPassword",
"vncUri":"vnc://127.0.0.1:5904?VncPassword=$initialVncPassword&SecurityType=2",
"commands":${jsonEncode(Localizations.localeOf(G.homePageStateContext).languageCode == 'zh' ? D.commands : D.commands4En)}
}""",
    ]);
    // ignore: use_build_context_synchronously
    // ignore: use_build_context_synchronously
    G.updateText.value = AppLocalizations.of(
      G.homePageStateContext,
    )!.installationComplete;
  }

  static Future<void> initData() async {
    G.dataPath = (await getApplicationSupportDirectory()).path;

    G.termPtys = {};

    G.keyboard = VirtualKeyboard(defaultInputHandler);

    G.prefs = await SharedPreferences.getInstance();

    // Set currentContainer early so getCurrentProp is safe during first-time init.
    // Use a direct prefs read (not Util.getGlobal) to avoid creating the key here,
    // since the first-launch check below depends on the key being absent.
    G.currentContainer = G.prefs.getInt("defaultContainer") ?? 0;

    G.settings = GlobalSettings();
    await G.settings.init(G.prefs);

    // Sync the showAdvancedLogs notifier so the LoadingPage reacts immediately.
    G.showAdvancedLogs.value = G.settings.advancedLogs;

    await Util.execute(
      "ln -sf ${Util.escapeShellArgument(await D.androidChannel.invokeMethod("getNativeLibraryPath", {}) as String)} ${Util.escapeShellArgument(G.dataPath)}/applib",
    );

    //如果没有这个key，说明是初次启动
    if (!G.prefs.containsKey("defaultContainer")) {
      await initForFirstTime();
      //根据用户的屏幕调整分辨率
      final s =
          WidgetsBinding.instance.platformDispatcher.views.first.physicalSize;
      final String w = (max(s.width, s.height) * 0.75).round().toString();
      final String h = (min(s.width, s.height) * 0.75).round().toString();
      G.postCommand =
          """sed -i -E "s@-geometry [0-9]+x[0-9]+@-geometry ${w}x$h@g" \$(command -v start-vnc) 2>/dev/null || true
sed -i -E 's/echo "[^"]+" \\| vncpasswd -f/echo "${_sanitizeVncPassword(Util.getCurrentProp("vncPassword"))}" | vncpasswd -f/g' \$(command -v start-vnc) 2>/dev/null || true""";
          // ignore: use_build_context_synchronously
      if (Localizations.localeOf(G.homePageStateContext).languageCode != 'zh') {
        G.postCommand +=
            "\nsed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && locale-gen";
        // For English users, assume they need to enable terminal write
        G.settings.isTerminalWriteEnabled = true;
        G.settings.isTerminalCommandsEnabled = true;
        G.settings.isStickyKey = false;
        G.settings.wakelock = true;
      }
      G.settings.getifaddrsBridge =
          (await DeviceInfoPlugin().androidInfo).version.sdkInt >= 31;

      // Show DE selection dialog and configure xinitrc + purge unchosen DE
      final String deChoice = await _showDeSelectionDialog();
      G.settings.selectedDE = deChoice;
      final String deExec = deChoice == 'lxqt' ? 'startlxqt' : 'startxfce4';
      final String deDesktop = deChoice == 'lxqt' ? 'LXQt' : 'XFCE';
      final String removePackages = deChoice == 'lxqt'
          ? 'xfce4 xfce4-goodies xfce4-terminal'
          : 'lxqt openbox';
      G.postCommand += """
cat > /home/tiny/.xinitrc << 'XINITRC'
#!/bin/bash
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=$deDesktop
exec $deExec
XINITRC
chmod +x /home/tiny/.xinitrc
pacman -Rns --noconfirm $removePackages 2>/dev/null || true""";
    }
    G.currentContainer = G.settings.defaultContainer;

    //是否需要重新安装引导包?
    if (Util.getGlobal("reinstallBootstrap")) {
      // ignore: use_build_context_synchronously
      G.updateText.value = AppLocalizations.of(
        G.homePageStateContext,
      )!.reinstallingBootPackage;
      await setupBootstrap();
      G.prefs.setBool("reinstallBootstrap", false);
    }

    //开启了什么图形界面？
    if (Util.getGlobal("useX11")) {
      G.wasX11Enabled = true;
      Workflow.launchXServer();
    } else if (Util.getGlobal("useAvnc")) {
      G.wasAvncEnabled = true;
    }

    G.termFontScale.value = Util.getGlobal("termFontScale") as double;

    G.controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);

    //设置屏幕常亮
    WakelockPlus.toggle(enable: Util.getGlobal("wakelock"));
  }

  static Future<void> initTerminalForCurrent() async {
    if (!G.termPtys.containsKey(G.currentContainer)) {
      G.termPtys[G.currentContainer] = TermPty();
    }
  }

  static Future<void> setupAudio() async {
    G.audioPty?.kill();
    G.audioPty = Pty.start("/system/bin/sh");
    G.audioPty!.write(
      const Utf8Encoder().convert("""
export DATA_DIR=${G.dataPath}
export PATH=\$DATA_DIR/bin:\$PATH
export LD_LIBRARY_PATH=\$DATA_DIR/lib
\$DATA_DIR/bin/busybox sed "s/4713/${Util.getGlobal("defaultAudioPort") as int}/g" \$DATA_DIR/bin/pulseaudio.conf > \$DATA_DIR/bin/pulseaudio.conf.tmp
rm -rf \$DATA_DIR/pulseaudio_tmp/*
TMPDIR=\$DATA_DIR/pulseaudio_tmp HOME=\$DATA_DIR/pulseaudio_tmp XDG_CONFIG_HOME=\$DATA_DIR/pulseaudio_tmp LD_LIBRARY_PATH=\$DATA_DIR/bin:\$LD_LIBRARY_PATH \$DATA_DIR/bin/pulseaudio -F \$DATA_DIR/bin/pulseaudio.conf.tmp
exit
"""),
    );
    await G.audioPty?.exitCode;
  }

  static Future<void> launchCurrentContainer() async {
    String extraMount = ""; //mount options and other proot options
    String extraOpt = "";
    if (Util.getGlobal("getifaddrsBridge")) {
      Util.executeBackground(
        "${Util.escapeShellArgument('${G.dataPath}/bin/getifaddrs_bridge_server')} ${Util.escapeShellArgument('${G.dataPath}/containers/${G.currentContainer}/tmp/.getifaddrs-bridge')}",
      );
      extraOpt +=
          "LD_PRELOAD=/home/tiny/.local/share/tiny/extra/getifaddrs_bridge_client_lib.so ";
    }
    if (Util.getGlobal("isHidpiEnabled")) {
      extraOpt += "${Util.getGlobal("defaultHidpiOpt")} ";
    }
    if (Util.getGlobal("virgl")) {
      Util.executeBackground(
        """
export DATA_DIR=${Util.escapeShellArgument(G.dataPath)}
export PATH=\$DATA_DIR/bin:\$PATH
export LD_LIBRARY_PATH=\$DATA_DIR/lib
export CONTAINER_DIR=\$DATA_DIR/containers/${G.currentContainer}
\$DATA_DIR/bin/virgl_test_server ${(Util.getGlobal("defaultVirglCommand").toString()).split(' ').where((s) => s.isNotEmpty).map(Util.escapeShellArgument).join(' ')}""",
      );
      extraOpt += "${Util.getGlobal("defaultVirglOpt")} ";
    }
    if (Util.getGlobal("turnip")) {
      extraOpt += "${Util.getGlobal("defaultTurnipOpt")} ";
      if (!(Util.getGlobal("dri3"))) {
        extraOpt += "MESA_VK_WSI_DEBUG=sw ";
      }
    }
    if (Util.getGlobal("isJpEnabled")) {
      extraOpt += "LANG=ja_JP.UTF-8 ";
    }
    extraMount += "--mount=\$DATA_DIR/tiny/font:/usr/share/fonts/tiny ";
    extraMount +=
        "--mount=\$DATA_DIR/tiny/extra/start-arch.sh:/usr/local/bin/start-arch.sh ";
    extraMount +=
        "--mount=\$DATA_DIR/tiny/extra/start-desktop:/usr/local/bin/start-desktop ";
    extraMount +=
        "--mount=\$DATA_DIR/tiny/extra/cmatrix:/home/tiny/.local/bin/cmatrix ";
    extraMount +=
        "--mount=\$DATA_DIR/tiny/extra/tiny_virtual_mic:/home/tiny/.local/bin/tiny_virtual_mic ";
    Util.termWrite("""
export DATA_DIR=${G.dataPath}
export PATH=\$DATA_DIR/bin:\$PATH
export LD_LIBRARY_PATH=\$DATA_DIR/lib
export CONTAINER_DIR=\$DATA_DIR/containers/${G.currentContainer}
export EXTRA_MOUNT=${Util.escapeShellArgument(extraMount)}
export EXTRA_OPT=${Util.escapeShellArgument(extraOpt)}
#export PROOT_L2S_DIR=\$DATA_DIR/containers/0/.l2s
cd \$DATA_DIR
export PROOT_TMP_DIR=\$DATA_DIR/proot_tmp
export PROOT_LOADER=\$DATA_DIR/applib/libproot-loader.so
export PROOT_LOADER_32=\$DATA_DIR/applib/libproot-loader32.so
${Util.getCurrentProp("boot")}
${G.postCommand}
clear""");
  }

  static Future<void> launchGUIBackend() async {
    Util.termWrite(
      (Util.getGlobal("autoLaunchVnc") as bool)
          ? ((Util.getGlobal("useX11") as bool)
                ? """mkdir -p "\$HOME/.vnc" && bash /etc/X11/xinit/xinitrc &> "\$HOME/.vnc/x.log" &"""
                : Util.getCurrentProp("vnc"))
          : "",
    );
    Util.termWrite("clear");
  }

  static Future<void> waitForConnection() async {
    await retry(
      // Make a GET request
      () => http
          .get(Uri.parse(Util.getCurrentProp("vncUrl")))
          .timeout(const Duration(milliseconds: 250)),
      // Retry on SocketException or TimeoutException
      retryIf: (e) => e is SocketException || e is TimeoutException,
    );
  }

  static Future<void> launchBrowser() async {
    G.controller.loadRequest(Uri.parse(Util.getCurrentProp("vncUrl")));
    Navigator.push(
      G.homePageStateContext,
      MaterialPageRoute(
        builder: (context) {
          return Focus(
            onKeyEvent: (node, event) {
              // Allow webview to handle cursor keys. Without this, the
              // arrow keys seem to get "eaten" by Flutter and therefore
              // never reach the webview.
              // (https://github.com/flutter/flutter/issues/102505).
              if (!kIsWeb) {
                if ({
                  LogicalKeyboardKey.arrowLeft,
                  LogicalKeyboardKey.arrowRight,
                  LogicalKeyboardKey.arrowUp,
                  LogicalKeyboardKey.arrowDown,
                  LogicalKeyboardKey.tab,
                }.contains(event.logicalKey)) {
                  return KeyEventResult.skipRemainingHandlers;
                }
              }
              return KeyEventResult.ignored;
            },
            child: GestureDetector(
              onSecondaryTap: () {},
              child: WebViewWidget(controller: G.controller),
            ),
          );
        },
      ),
    );
  }

  static Future<void> launchAvnc() async {
    await AvncFlutter.launchUsingUri(
      Util.getCurrentProp("vncUri") as String,
      resizeRemoteDesktop: Util.getGlobal("avncResizeDesktop") as bool,
      resizeRemoteDesktopScaleFactor: pow(
        4,
        Util.getGlobal("avncScaleFactor") as double,
      ).toDouble(),
    );
  }

  static Future<void> launchXServer() async {
    await X11Flutter.launchXServer(
      "${G.dataPath}/containers/${G.currentContainer}/tmp",
      "${G.dataPath}/containers/${G.currentContainer}/usr/share/X11/xkb",
      [":4", "-extension", "MIT-SHM"],
    );
  }

  static Future<void> launchX11() async {
    await X11Flutter.launchX11Page();
  }

  static Future<void> workflow() async {
    final hasPermission = await grantPermissions();
    if (!hasPermission) {
      debugPrint("Storage permission denied. Initialization aborted.");
      return;
    }
    await initData();
    await initTerminalForCurrent();
    setupAudio();
    launchCurrentContainer();
    if (Util.getGlobal("autoLaunchVnc") as bool) {
      if (G.wasX11Enabled) {
        await Util.waitForXServer();
        launchGUIBackend();
        launchX11();
        return;
      }
      launchGUIBackend();
      waitForConnection().then(
        (value) => G.wasAvncEnabled ? launchAvnc() : launchBrowser(),
      );
    }
  }
}

// Simple card widget used in the DE selection dialog.
class _DeCard extends StatelessWidget {
  final String name;
  final String description;
  final String buttonLabel;
  final VoidCallback onTap;

  const _DeCard({
    required this.name,
    required this.description,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              name,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onTap, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }
}

class ShizukuHelper {
  static bool _available = false;

  @visibleForTesting
  static Future<ProcessResult> Function(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment,
    bool runInShell,
    Encoding? stdoutEncoding,
    Encoding? stderrEncoding,
  })
  processRunner = Process.run;

  static Future<void> init() async {
    try {
      final result = await processRunner('sh', ['-c', 'command -v rish']);
      _available = result.exitCode == 0;
    } catch (_) {
      _available = false;
    }
  }

  static bool get isAvailable => _available;

  // Single-quote escapes an argument for safe use inside a shell command string.
  static String _escapeArg(String arg) => "'${arg.replaceAll("'", "'\\''")}'";

  static Future<ProcessResult> run(
    String executable,
    List<String> arguments,
  ) async {
    if (!_available) {
      return processRunner(executable, arguments);
    }
    // rish only accepts a single command string, so we shell-escape every
    // argument to prevent command injection.
    final cmdString = [executable, ...arguments].map(_escapeArg).join(' ');
    return processRunner('rish', ['-c', cmdString]);
  }
}
