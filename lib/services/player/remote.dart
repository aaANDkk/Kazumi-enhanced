import 'dart:async';

import 'package:dlna_dart/dlna.dart';
import 'package:flutter/material.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/services/logging/logger.dart';
import 'package:kazumi/bean/widget/app_icon.dart';

class RemotePlay {
  Future<void> castVideo(String video, {required String title}) async {
    final searcher = DLNAManager();
    final dlna = await searcher.start();
    StreamSubscription<Map<String, DLNADevice>>? subscription;
    final loggedDevices = <String>{};
    List<Widget> dlnaDevice = [];
    await KazumiDialog.show(builder: (BuildContext context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text('远程投屏'),
          content: SingleChildScrollView(
            child: Column(
              children: dlnaDevice,
            ),
          ),
          actions: [
            const SizedBox(width: 20),
            TextButton(
              onPressed: () {
                KazumiDialog.dismiss();
              },
              child: Text(
                '退出',
                style: TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
            ),
            TextButton(
                onPressed: () {
                  KazumiDialog.showToast(
                    message: '开始搜索',
                  );
                  // The device stream is single-subscription.
                  subscription ??= dlna.devices.stream.listen((deviceList) {
                    final tiles = <Widget>[];
                    deviceList.forEach((key, value) {
                      final castable = _supportsAVTransport(value);
                      if (loggedDevices.add(key)) {
                        KazumiLogger().i(
                            'RemotePlay: found ${value.info.friendlyName} ${value.info.deviceType} ${value.info.URLBase}${castable ? '' : ', skipped without AVTransport'}');
                      }
                      if (!castable) {
                        return;
                      }
                      final typeName = _deviceTypeName(value.info.deviceType);
                      tiles.add(ListTile(
                          leading: _deviceUPnPIcon(typeName),
                          title: Text(value.info.friendlyName),
                          subtitle: Text(typeName),
                          onTap: () async {
                            try {
                              KazumiDialog.showToast(
                                message: '尝试投屏至 ${value.info.friendlyName}',
                              );
                              await value.setUrl(video, title: title);
                              await value.play();
                            } catch (e) {
                              KazumiLogger().e(
                                  'RemotePlay: failed to cast to device',
                                  error: e);
                              KazumiDialog.showToast(
                                message: 'DLNA 异常: $e \n尝试重新进入 DLNA 投屏或切换设备',
                              );
                            }
                          }));
                    });
                    // Also rebuild when empty, so pruned devices disappear.
                    setState(() {
                      dlnaDevice = tiles;
                    });
                  });
                },
                child: Text(
                  '搜索',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.outline),
                )),
          ],
        );
      });
    }, onDismiss: () {
      subscription?.cancel();
      searcher.stop();
    });
  }

  // DLNADevice.controlURL resolves every cast request through this service.
  bool _supportsAVTransport(DLNADevice device) {
    return device.info.serviceList
        .any((service) => '${service['serviceId']}'.contains('AVTransport'));
  }

  String _deviceTypeName(String deviceType) {
    final parts = deviceType.split(':');
    return parts.length > 3 ? parts[3] : deviceType;
  }

  AppIcon _deviceUPnPIcon(String deviceType) {
    switch (deviceType) {
      case 'MediaRenderer':
        return const AppIcon(Icons.cast_connected);
      case 'MediaServer':
        return const AppIcon(Icons.cast_connected);
      case 'InternetGatewayDevice':
        return const AppIcon(Icons.router);
      case 'BasicDevice':
        return const AppIcon(Icons.device_hub);
      case 'DimmableLight':
        return const AppIcon(Icons.lightbulb);
      case 'WLANAccessPoint':
        return const AppIcon(Icons.lan);
      case 'WLANConnectionDevice':
        return const AppIcon(Icons.wifi_tethering);
      case 'Printer':
        return const AppIcon(Icons.print);
      case 'Scanner':
        return const AppIcon(Icons.scanner);
      case 'DigitalSecurityCamera':
        return const AppIcon(Icons.camera_enhance_outlined);
      default:
        return const AppIcon(Icons.question_mark);
    }
  }
}
