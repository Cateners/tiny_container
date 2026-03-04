class CommandInfo {
  String name;
  String command;

  CommandInfo({required this.name, required this.command});

  factory CommandInfo.fromJson(Map<String, dynamic> json) {
    return CommandInfo(
      name: json['name'] as String,
      command: json['command'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'command': command};
  }
}

class ContainerInfo {
  String name;
  String boot;
  String vnc;
  String vncPassword;
  String vncUrl;
  String vncUri;
  List<dynamic> commands;

  // To preserve dynamically added fields in JSON that we might not know about
  Map<String, dynamic> additionalProps;

  ContainerInfo({
    required this.name,
    required this.boot,
    required this.vnc,
    required this.vncPassword,
    required this.vncUrl,
    required this.vncUri,
    required this.commands,
    this.additionalProps = const {},
  });

  factory ContainerInfo.fromJson(Map<String, dynamic> json) {
    final knownKeys = [
      'name',
      'boot',
      'vnc',
      'vncPassword',
      'vncUrl',
      'vncUri',
      'commands',
    ];

    final extraProps = <String, dynamic>{};
    for (final key in json.keys) {
      if (!knownKeys.contains(key)) {
        extraProps[key] = json[key];
      }
    }

    return ContainerInfo(
      name: json['name'] as String? ?? 'Debian Trixie',
      boot: json['boot'] as String? ?? '',
      vnc: json['vnc'] as String? ?? 'startnovnc &',
      vncPassword: json['vncPassword'] as String? ?? '',
      vncUrl: json['vncUrl'] as String? ?? '',
      vncUri: json['vncUri'] as String? ?? '',
      commands: json['commands'] as List<dynamic>? ?? [],
      additionalProps: extraProps,
    );
  }

  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{
      'name': name,
      'boot': boot,
      'vnc': vnc,
      'vncPassword': vncPassword,
      'vncUrl': vncUrl,
      'vncUri': vncUri,
      'commands': commands,
    };
    result.addAll(additionalProps);
    return result;
  }

  dynamic getProp(String key) {
    switch (key) {
      case 'name':
        return name;
      case 'boot':
        return boot;
      case 'vnc':
        return vnc;
      case 'vncPassword':
        return vncPassword;
      case 'vncUrl':
        return vncUrl;
      case 'vncUri':
        return vncUri;
      case 'commands':
        return commands;
      default:
        return additionalProps[key];
    }
  }

  void setProp(String key, dynamic value) {
    switch (key) {
      case 'name':
        name = value;
        break;
      case 'boot':
        boot = value;
        break;
      case 'vnc':
        vnc = value;
        break;
      case 'vncPassword':
        vncPassword = value;
        break;
      case 'vncUrl':
        vncUrl = value;
        break;
      case 'vncUri':
        vncUri = value;
        break;
      case 'commands':
        commands = value;
        break;
      default:
        additionalProps[key] = value;
        break;
    }
  }

  bool hasProp(String key) {
    switch (key) {
      case 'name':
        return true;
      case 'boot':
        return true;
      case 'vnc':
        return true;
      case 'vncPassword':
        return true;
      case 'vncUrl':
        return true;
      case 'vncUri':
        return true;
      case 'commands':
        return true;
      default:
        return additionalProps.containsKey(key);
    }
  }
}
