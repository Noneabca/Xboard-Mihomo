import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class VPNItem extends ConsumerWidget {
  const VPNItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final enable =
        ref.watch(vpnSettingProvider.select((state) => state.enable));
    return ListItem.switchItem(
      title: const Text("VPN"),
      subtitle: Text(appLocalizations.vpnEnableDesc),
      delegate: SwitchDelegate(
        value: enable,
        onChanged: (value) async {
          ref.read(vpnSettingProvider.notifier).updateState(
                (state) => state.copyWith(
                  enable: value,
                ),
              );
        },
      ),
    );
  }
}

class AllowBypassItem extends ConsumerWidget {
  const AllowBypassItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final allowBypass =
        ref.watch(vpnSettingProvider.select((state) => state.allowBypass));
    return ListItem.switchItem(
      title: Text(appLocalizations.allowBypass),
      subtitle: Text(appLocalizations.allowBypassDesc),
      delegate: SwitchDelegate(
        value: allowBypass,
        onChanged: (bool value) async {
          ref.read(vpnSettingProvider.notifier).updateState(
                (state) => state.copyWith(
                  allowBypass: value,
                ),
              );
        },
      ),
    );
  }
}

class VpnSystemProxyItem extends ConsumerWidget {
  const VpnSystemProxyItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final systemProxy =
        ref.watch(vpnSettingProvider.select((state) => state.systemProxy));
    return ListItem.switchItem(
      title: Text(appLocalizations.systemProxy),
      subtitle: Text(appLocalizations.systemProxyDesc),
      delegate: SwitchDelegate(
        value: systemProxy,
        onChanged: (bool value) async {
          ref.read(vpnSettingProvider.notifier).updateState(
                (state) => state.copyWith(
                  systemProxy: value,
                ),
              );
        },
      ),
    );
  }
}

class SystemProxyItem extends ConsumerWidget {
  const SystemProxyItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final systemProxy =
        ref.watch(networkSettingProvider.select((state) => state.systemProxy));

    return ListItem.switchItem(
      title: Text(appLocalizations.systemProxy),
      subtitle: Text(appLocalizations.systemProxyDesc),
      delegate: SwitchDelegate(
        value: systemProxy,
        onChanged: (bool value) async {
          ref.read(networkSettingProvider.notifier).updateState(
                (state) => state.copyWith(
                  systemProxy: value,
                ),
              );
        },
      ),
    );
  }
}

class Ipv6Item extends ConsumerWidget {
  const Ipv6Item({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final ipv6 = ref.watch(vpnSettingProvider.select((state) => state.ipv6));
    return ListItem.switchItem(
      title: const Text("IPv6"),
      subtitle: Text(appLocalizations.ipv6InboundDesc),
      delegate: SwitchDelegate(
        value: ipv6,
        onChanged: (bool value) async {
          ref.read(vpnSettingProvider.notifier).updateState(
                (state) => state.copyWith(
                  ipv6: value,
                ),
              );
        },
      ),
    );
  }
}

class AutoSetSystemDnsItem extends ConsumerWidget {
  const AutoSetSystemDnsItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final autoSetSystemDns = ref.watch(
        networkSettingProvider.select((state) => state.autoSetSystemDns));
    return ListItem.switchItem(
      title: Text(appLocalizations.autoSetSystemDns),
      delegate: SwitchDelegate(
        value: autoSetSystemDns,
        onChanged: (bool value) async {
          ref.read(networkSettingProvider.notifier).updateState(
                (state) => state.copyWith(
                  autoSetSystemDns: value,
                ),
              );
        },
      ),
    );
  }
}

// [已移除] TunStackItem - TUN 模式相关组件已禁用
// class TunStackItem extends ConsumerWidget {
//   const TunStackItem({super.key});
//   @override
//   Widget build(BuildContext context, ref) {
//     ...
//   }
// }

class BypassDomainItem extends StatelessWidget {
  const BypassDomainItem({super.key});

  _initActions(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      context.commonScaffoldState?.actions = [
        IconButton(
          onPressed: () async {
            final res = await globalState.showMessage(
              title: appLocalizations.reset,
              message: TextSpan(
                text: appLocalizations.resetTip,
              ),
            );
            if (res != true) {
              return;
            }
            ref.read(networkSettingProvider.notifier).updateState(
                  (state) => state.copyWith(
                    bypassDomain: defaultBypassDomain,
                  ),
                );
          },
          tooltip: appLocalizations.reset,
          icon: const Icon(
            Icons.replay,
          ),
        )
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      title: Text(appLocalizations.bypassDomain),
      subtitle: Text(appLocalizations.bypassDomainDesc),
      delegate: OpenDelegate(
        blur: false,
        title: appLocalizations.bypassDomain,
        widget: Consumer(
          builder: (_, ref, __) {
            _initActions(context, ref);
            final bypassDomain = ref.watch(
                networkSettingProvider.select((state) => state.bypassDomain));
            return ListInputPage(
              title: appLocalizations.bypassDomain,
              items: bypassDomain,
              titleBuilder: (item) => Text(item),
              onChange: (items) {
                ref.read(networkSettingProvider.notifier).updateState(
                      (state) => state.copyWith(
                        bypassDomain: List.from(items),
                      ),
                    );
              },
            );
          },
        ),
      ),
    );
  }
}

// [已移除] RouteModeItem - TUN 模式相关组件已禁用
// class RouteModeItem extends ConsumerWidget {
//   ...
// }

// [已移除] RouteAddressItem - TUN 模式相关组件已禁用
// class RouteAddressItem extends ConsumerWidget {
//   ...
// }

final networkItems = [
  if (Platform.isAndroid) const VPNItem(),
  if (Platform.isAndroid)
    ...generateSection(
      title: "VPN",
      items: [
        const VpnSystemProxyItem(),
        const BypassDomainItem(),
        const AllowBypassItem(),
        const Ipv6Item(),
      ],
    ),
  if (system.isDesktop)
    ...generateSection(
      title: appLocalizations.system,
      items: [
        SystemProxyItem(),
        BypassDomainItem(),
      ],
    ),
  ...generateSection(
    title: appLocalizations.options,
    items: [
      // [已禁用] Windows上TUN模式存在兼容性问题，暂时移除
      // if (system.isDesktop) const TUNItem(),
      // const TunStackItem(),  // TUN 相关
      // const RouteModeItem(),  // TUN 相关
      // const RouteAddressItem(),  // TUN 相关
      if (Platform.isMacOS) const AutoSetSystemDnsItem(),
    ],
  ),
];

class NetworkListView extends ConsumerWidget {
  const NetworkListView({super.key});

  _initActions(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      context.commonScaffoldState?.actions = [
        IconButton(
          onPressed: () async {
            final res = await globalState.showMessage(
              title: appLocalizations.reset,
              message: TextSpan(
                text: appLocalizations.resetTip,
              ),
            );
            if (res != true) {
              return;
            }
            ref.read(vpnSettingProvider.notifier).updateState(
                  (state) => defaultVpnProps.copyWith(
                    accessControl: state.accessControl,
                  ),
                );
            // [已移除] TUN 配置重置逻辑
            // ref.read(patchClashConfigProvider.notifier).updateState(
            //       (state) => state.copyWith(
            //         tun: defaultTun,
            //       ),
            //     );
          },
          tooltip: appLocalizations.reset,
          icon: const Icon(
            Icons.replay,
          ),
        )
      ];
    });
  }

  @override
  Widget build(BuildContext context, ref) {
    _initActions(context, ref);
    return generateListView(
      networkItems,
    );
  }
}
