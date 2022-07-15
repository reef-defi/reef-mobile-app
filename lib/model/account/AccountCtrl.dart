import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:reef_mobile_app/model/StorageKey.dart';
import 'package:reef_mobile_app/model/account/ReefSigner.dart';
import 'package:reef_mobile_app/service/JsApiService.dart';
import 'package:reef_mobile_app/service/StorageService.dart';

import 'account.dart';

class AccountCtrl {
  final Account account = Account();
  final JsApiService jsApi;

  AccountCtrl(this.jsApi, StorageService storage) {
    initSavedDeviceAccountAddress(jsApi, storage);
    initJsObservables(jsApi, storage);
    initWasm(jsApi);
  }

  void initJsObservables(JsApiService jsApi, StorageService storage) {
    jsApi.jsObservable('account.selectedSigner\$').listen((signer) async {
      LinkedHashMap s = signer;
      await storage.setValue(StorageKey.selected_address.name, s['address']);
      account.setSelectedSigner(ReefSigner(s["address"], s["name"]));
    });

    jsApi.jsObservable('account.availableSigners\$').listen((signers) async {
      print('AVAILABLE Signers=$signers');
    });
  }

  void initSavedDeviceAccountAddress(
      JsApiService jsApi, StorageService storage) async {
    // TODO check if this address also exists in keystore
    var savedAddress = await storage.getValue(StorageKey.selected_address.name);
    if (kDebugMode) {
      print('SET SAVED ADDRESS=$savedAddress');
    }
    if (savedAddress != null) {
      jsApi.jsCall('appState.setCurrentAddress("$savedAddress")');
    }
  }

  void initWasm(JsApiService jsApi) async {
    await jsApi.jsPromise('keyring.initWasm()');
  }

  Future<String> generateAccount() async {
    return await jsApi.jsPromise('keyring.generate()');
  }

  Future<String> checkMnemonicValid(String mnemonic) async {
    return await jsApi.jsPromise('keyring.checkMnemonicValid("$mnemonic")');
  }

  Future<String> accountFromMnemonic(String mnemonic) async {
    return await jsApi.jsPromise('keyring.accountFromMnemonic("$mnemonic")');
  }
}
