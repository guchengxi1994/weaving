import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weaving/style/app_style.dart';

class DataTransferScreen extends ConsumerStatefulWidget {
  const DataTransferScreen({super.key});

  @override
  ConsumerState<DataTransferScreen> createState() => _DataTransferScreenState();
}

class _DataTransferScreenState extends ConsumerState<DataTransferScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(borderRadius: AppStyle.leftTopRadius),
      child: Center(
        // child: ElevatedButton(
        //     onPressed: () {
        //       UdpServer.instance.startUdpServer();
        //     },
        //     child: const Text("server")),
        child: Image.asset("assets/under_dev.png"),
      ),
    );
  }
}
