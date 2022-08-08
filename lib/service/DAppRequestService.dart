import 'dart:convert';

import 'package:reef_mobile_app/model/ReefAppState.dart';

import 'JsApiService.dart';

class DAppRequestService {
  const DAppRequestService();

  void handleDAppMsgRequest(JsApiMessage message, void Function(String reqId, dynamic value) responseFn) async {
    if (message.msgType == 'pub(phishing.redirectIfDenied)') {
      responseFn(message.reqId, _redirectIfPhishing(message.value['url']));
    }

    if (message.msgType != 'pub(authorize.tab)' && !_ensureUrlAuthorized(message.url)) {
      print('Domain not authorized= ${message.url}');
      // TODO display alert so user is aware domain is disabled
      return;
    }

    switch(message.msgType){
      case 'pub(bytes.sign)':
        var signature = await ReefAppState.instance.signingCtrl.signRaw(message.value['address'], message.value['data']);
        responseFn(message.reqId, '${jsonEncode(signature)}');
        break;
      case 'pub(extrinsic.sign)':
        var signature = await ReefAppState.instance.signingCtrl.signPayload(message.value['address'], message.value);
        responseFn(message.reqId, '${jsonEncode(signature)}');
        break;
      case 'pub(authorize.tab)':
        responseFn(message.reqId, _authorizeDapp(message.value['origin'], message.url));
        break;

      case 'pub(accounts.list)':
        var accounts = await ReefAppState.instance.accountCtrl.getAccountsList();
        responseFn(message.reqId, '${jsonEncode(accounts)}');
        break;
    }
  }

  bool _redirectIfPhishing(String url) {
    // TODO check against list
    return false;
  }

  bool _ensureUrlAuthorized(String? url) {
    if(url == null){
      return false;
    }
    // TODO check against authorized domains
    return true;
  }

  _authorizeDapp(String dAppName, String? url) {
    if(url == null){
      return false;
    }
    // TODO display modal and save url for _ensureUrlAuthorized
    return true;
  }
}
