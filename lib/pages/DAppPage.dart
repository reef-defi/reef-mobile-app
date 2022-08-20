import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reef_mobile_app/service/DAppRequestService.dart';
import 'package:reef_mobile_app/service/JsApiService.dart';
import 'package:http/http.dart' as http;

import '../components/SignatureContentToggle.dart';
import '../model/ReefAppState.dart';

class DAppPage extends StatefulWidget {
  final url = 'https://min-dapp.web.app';
  // final url = 'https://app.reef.io';
  final ReefAppState reefState;
  final DAppRequestService dAppRequestService = const DAppRequestService();

  const DAppPage(this.reefState);

  Future<String> _getHtml(String url) async {
    return http.read(Uri.parse(url));
  }

  @override
  State<DAppPage> createState() => _DAppPageState();

}

class _DAppPageState extends State<DAppPage> {
  JsApiService? dappJsApi;

  @override
  void initState() {
    super.initState();

    widget._getHtml(widget.url).then((html) {
      setState(() {
        dappJsApi = JsApiService.dAppInjectedHtml(html, widget.url);
        dappJsApi?.jsDAppMsgSubj.listen((value) {
          widget.dAppRequestService
              .handleDAppMsgRequest(value, dappJsApi!.sendDappMsgResponse);
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SignatureContentToggle(Scaffold(
      appBar: AppBar(
        title: const Text('DApp'),
      ),
      body: Center(
          child: dappJsApi != null
              ? dappJsApi!.widget
              : const CircularProgressIndicator()),
    ));
  }
}
