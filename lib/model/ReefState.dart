import 'dart:convert';

import 'package:reef_mobile_app/model/tokens/TokensCtrl.dart';
import 'package:reef_mobile_app/service/JsApiService.dart';
import 'package:reef_mobile_app/service/StorageService.dart';

import 'account/AccountCtrl.dart';

class ReefState{
  final JsApiService jsApi;
  final StorageService storage;
  late TokenCtrl tokensCtrl;
  late AccountCtrl accountCtrl;

  ReefState(JsApiService this.jsApi, StorageService this.storage) {
    _initAsync(jsApi);
    tokensCtrl = TokenCtrl(jsApi);
    accountCtrl = AccountCtrl(jsApi, storage);
  }

  void _initAsync(JsApiService jsApi) async{
    await _initReefState(jsApi);
    await _initReefObservables(jsApi);
  }

  _initReefState(JsApiService jsApiService) async{
    var injectSigners = [{
      "name": 'test',
      "signer": '',
      "balance": '123000000000000000000',
      "address": '5EUWG6tCA9S8Vw6YpctbPHdSrj95d18uNhRqgDniW3g9ZoYc',
      "evmAddress": '',
      "isEvmClaimed": false,
      "source": 'mobileApp',
      "genesisHash": 'undefined'
    }];
    // var availableNetworks = jsonDecode(await jsApiService.jsCall('jsApi.availableNetworks'));
    await jsApiService.jsCall('jsApi.initReefState("testnet", ${jsonEncode(injectSigners)})');
  }

  _initReefObservables(JsApiService jsApiService) async {
    jsApiService.jsMessageUnknownSubj.listen((JsApiMessage value) {
      print('jsMSG not handled id=${value.id}');
    });

  }
}