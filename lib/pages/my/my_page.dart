import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'package:kazumi/bean/appbar/sys_app_bar.dart';
import 'package:kazumi/pages/menu/route_visibility.dart';
import 'package:kazumi/pages/my/my_controller.dart';
import 'package:kazumi/pages/my/my_space_view.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key, required this.controller});

  final MyController controller;

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  bool _attached = false;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    widget.controller.scrollToTop = _scrollToTop;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setAttached(!RouteVisibility.isCoveredOf(context));
  }

  @override
  void didUpdateWidget(covariant MyPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller.scrollToTop == _scrollToTop) {
        oldWidget.controller.scrollToTop = null;
      }
      widget.controller.scrollToTop = _scrollToTop;
      if (_attached) {
        oldWidget.controller.detach();
        widget.controller.attach();
      }
    }
  }

  @override
  void dispose() {
    if (widget.controller.scrollToTop == _scrollToTop) {
      widget.controller.scrollToTop = null;
    }
    _scrollController.dispose();
    _setAttached(false);
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      for (final position in _scrollController.positions) {
        position.animateTo(
          0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _setAttached(bool value) {
    if (_attached == value) return;
    _attached = value;
    if (value) {
      widget.controller.attach();
    } else {
      widget.controller.detach();
    }
  }

  void _open(MyDestination destination) =>
      context.pushNamed(switch (destination) {
        MyDestination.theme => '/settings/theme',
        MyDestination.player => '/settings/player',
        MyDestination.danmaku => '/settings/danmaku/',
        MyDestination.rules => '/settings/plugin/',
        MyDestination.history => '/settings/history/',
        MyDestination.downloads => '/settings/download/',
        MyDestination.sync => '/settings/sync',
        MyDestination.storage => '/settings/storage',
        MyDestination.about => '/settings/about/',
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SysAppBar(
        toolbarHeight: 72,
        title: Text(
          '我的',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        needTopOffset: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: MySettingsButton(
              onTap: () => context.pushNamed('/settings/'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Observer(
          builder: (context) => MySpaceView(
            stats: widget.controller.watchStats,
            onOpen: _open,
            controller: _scrollController,
          ),
        ),
      ),
    );
  }
}
