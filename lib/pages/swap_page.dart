import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reef_mobile_app/components/modals/token_selection_modals.dart';
import 'package:reef_mobile_app/model/ReefAppState.dart';
import 'package:reef_mobile_app/model/StorageKey.dart';
import 'package:reef_mobile_app/model/swap/swap_settings.dart';
import 'package:reef_mobile_app/model/tokens/TokenWithAmount.dart';
import 'package:reef_mobile_app/utils/functions.dart';
import 'package:reef_mobile_app/utils/styles.dart';
import 'package:shimmer/shimmer.dart';

import '../components/SignatureContentToggle.dart';

class SwapPage extends StatefulWidget {
  const SwapPage({Key? key}) : super(key: key);

  @override
  State<SwapPage> createState() => _SwapPageState();
}

class _SwapPageState extends State<SwapPage> {
  var tokens = ReefAppState.instance.model.tokens.tokenList;

  // TODO: auto-select REEF token
  TokenWithAmount selectedToken = TokenWithAmount(
      name: 'REEF',
      address: '0x0000000000000000000000000000000001000000',
      iconUrl: 'https://s2.coinmarketcap.com/static/img/coins/64x64/6951.png',
      symbol: 'REEF',
      balance: BigInt.parse('1542087625938626180855'),
      decimals: 18,
      amount: BigInt.zero,
      price: 0.0841);
  // TODO: bottom token should be empty on start
  TokenWithAmount selectedBottomToken = TokenWithAmount(
      name: 'Free Mint Token',
      address: '0x4676199AdA480a2fCB4b2D4232b7142AF9fe9D87',
      iconUrl: '',
      symbol: 'FMT',
      balance: BigInt.parse('2761008739220176308876'),
      decimals: 18,
      amount: BigInt.zero,
      price: 0);

  SwapSettings settings = SwapSettings(1, 0.8);

  TextEditingController amountController = TextEditingController();
  String reserveTop = "";
  TextEditingController amountBottomController = TextEditingController();
  String reserveBottom = "";

  void _changeSelectedToken(TokenWithAmount token) {
    setState(() {
      selectedToken = token.setAmount("0");
      selectedBottomToken = selectedBottomToken.setAmount("0");
      _getPoolReserves();
    });
  }

  void _changeSelectedBottomToken(TokenWithAmount token) {
    setState(() {
      selectedBottomToken = token.setAmount("0");
      selectedToken = selectedToken.setAmount("0");
      _getPoolReserves();
    });
  }

  void _getPoolReserves() async {
    var res = await ReefAppState.instance.swapCtrl
        .getPoolReserves(selectedToken.address, selectedBottomToken.address);
    if (res is bool && res == false) {
      print("ERROR: Pool does not exist");
      reserveTop = "";
      reserveBottom = "";
      return;
    }

    reserveTop = res["reserve1"];
    reserveBottom = res["reserve2"];
    print("Pool reserves: ${res['reserve1']}, ${res['reserve1']}");
  }

  Future<void> _amountTopUpdated(String value) async {
    var formattedValue =
        _toStringWithoutDecimals(value, selectedToken.decimals);

    if (value.isEmpty ||
        formattedValue.replaceAll(".", "").replaceAll("0", "").isEmpty) {
      print("ERROR: Invalid value");
      selectedBottomToken = selectedBottomToken.setAmount("0");
      return;
    }

    selectedToken = selectedToken.setAmount(formattedValue);

    if (BigInt.parse(formattedValue) > selectedToken.balance) {
      print("WARN: Insufficient ${selectedToken.symbol} balance");
    }

    if (reserveTop.isEmpty) {
      return; // Pool does not exist
    }

    var token1 = selectedToken.setAmount(reserveTop);
    var token2 = selectedBottomToken.setAmount(reserveBottom);

    var res = (await ReefAppState.instance.swapCtrl
            .getSwapAmount(value, false, token1, token2))
        .replaceAll("\"", "");

    selectedBottomToken = selectedBottomToken.setAmount(res);

    print(
        "${selectedToken.amount} - ${toAmountDisplayBigInt(selectedToken.amount, decimals: selectedToken.decimals)}");
    print(
        "${selectedBottomToken.amount} - ${toAmountDisplayBigInt(selectedBottomToken.amount, decimals: selectedBottomToken.decimals)}");
  }

  Future<void> _amountBottomUpdated(String value) async {
    var formattedValue =
        _toStringWithoutDecimals(value, selectedToken.decimals);

    if (value.isEmpty ||
        formattedValue.replaceAll(".", "").replaceAll("0", "").isEmpty) {
      print("ERROR: Invalid value");
      selectedToken = selectedToken.setAmount("0");
      return;
    }

    selectedBottomToken = selectedBottomToken.setAmount(formattedValue);

    if (reserveTop.isEmpty) {
      return; // Pool does not exist
    }

    if (BigInt.parse(formattedValue) > BigInt.parse(reserveBottom)) {
      print(
          "ERROR: Insufficient ${selectedBottomToken.symbol} liquidity in pool");
      selectedToken = selectedToken.setAmount("0");
      return;
    }

    var token1 = selectedToken.setAmount(reserveTop);
    var token2 = selectedBottomToken.setAmount(reserveBottom);

    var res = (await ReefAppState.instance.swapCtrl
            .getSwapAmount(value, true, token1, token2))
        .replaceAll("\"", "");

    if (BigInt.parse(res) > selectedToken.balance) {
      print("WARN: Insufficient ${selectedToken.symbol} balance");
    }

    selectedToken = selectedToken.setAmount(res);

    print(
        "${selectedToken.amount} - ${toAmountDisplayBigInt(selectedToken.amount, decimals: selectedToken.decimals)}");
    print(
        "${selectedBottomToken.amount} - ${toAmountDisplayBigInt(selectedBottomToken.amount, decimals: selectedBottomToken.decimals)}");
  }

  void _executeSwap() async {
    if (selectedToken.amount <= BigInt.zero) {
      return;
    }
    var signerAddress = await ReefAppState.instance.storage
        .getValue(StorageKey.selected_address.name);
    var res = await ReefAppState.instance.swapCtrl.swapTokens(
        signerAddress, selectedToken, selectedBottomToken, settings);
    _getPoolReserves();
    print(res);
    print(
        "Balance ${selectedToken.symbol}: ${toAmountDisplayBigInt(selectedToken.balance, decimals: selectedToken.decimals)}");
    print(
        "Balance ${selectedBottomToken.symbol}: ${toAmountDisplayBigInt(selectedBottomToken.balance, decimals: selectedBottomToken.decimals)}");
  }

  String _toAmountDisplay(String amount, int decimals) {
    return (BigInt.parse(amount) / BigInt.from(10).pow(decimals))
        .toStringAsFixed(decimals);
  }

  String _toStringWithoutDecimals(String amount, int decimals) {
    var arr = amount.split(".");

    var intPart = arr[0];
    if (arr.length == 1) {
      for (int i = 0; i < decimals; i++) {
        intPart += "0";
      }
      return intPart;
    }

    while (intPart.startsWith("0")) {
      intPart = intPart.substring(1);
    }

    var fractionalPart = arr[1];
    while (fractionalPart.length < decimals) {
      fractionalPart += "0";
    }

    return intPart + fractionalPart;
  }

  @override
  Widget build(BuildContext context) {
    return SignatureContentToggle(Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24),
      child: Column(
        children: [
          Text(
            "Swap",
            style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w500,
                fontSize: 24,
                color: Colors.grey[800]),
          ),
          const Gap(24),
          Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Column(
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xffe1e2e8)),
                        borderRadius: BorderRadius.circular(12),
                        color: Styles.boxBackgroundColor,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              MaterialButton(
                                onPressed: () {
                                  showTokenSelectionModal(context,
                                      callback: _changeSelectedToken);
                                },
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                minWidth: 0,
                                height: 36,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(
                                        color: Colors.black26)),
                                child: Row(
                                  children: [
                                    if (selectedToken.iconUrl!.isNotEmpty)
                                      CachedNetworkImage(
                                        imageUrl: selectedToken.iconUrl ?? "",
                                        width: 24,
                                        height: 24,
                                        placeholder: (context, url) =>
                                            Shimmer.fromColors(
                                          baseColor: Colors.grey[300]!,
                                          highlightColor: Colors.grey[350]!,
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            decoration: ShapeDecoration(
                                              color: Colors.grey[350]!,
                                              shape: const CircleBorder(),
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            const Icon(
                                          CupertinoIcons
                                              .exclamationmark_circle_fill,
                                          color: Colors.black12,
                                          size: 24,
                                        ),
                                      )
                                    else
                                      Icon(CupertinoIcons.question_circle,
                                          color: Colors.grey[600]!, size: 24),
                                    const Gap(4),
                                    Text(selectedToken.symbol),
                                    const Gap(4),
                                    Icon(CupertinoIcons.chevron_down,
                                        size: 16, color: Styles.textLightColor)
                                  ],
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[\.0-9]'))
                                  ],
                                  keyboardType: TextInputType.number,
                                  controller: amountController,
                                  onChanged: (text) async {
                                    await _amountTopUpdated(
                                        amountController.text);
                                    // setState(() {
                                    //   //you can access nameController in its scope to get
                                    //   // the value of text entered as shown below
                                    //   selectedToken.amount = amountController.text;
                                    // });
                                  },
                                  decoration: InputDecoration(
                                      constraints:
                                          const BoxConstraints(maxHeight: 32),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                      enabledBorder: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.transparent),
                                      ),
                                      border: const OutlineInputBorder(),
                                      focusedBorder: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.transparent,
                                        ),
                                      ),
                                      hintText: '0.0',
                                      hintStyle: TextStyle(
                                          color: Styles.textLightColor)),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                          const Gap(8),
                          SizedBox(
                            width: double.infinity,
                            child: Row(
                              children: [
                                Text(
                                  "Balance: ${toAmountDisplayBigInt(
                                    selectedToken.balance, decimals: selectedToken.decimals)} ${selectedToken.symbol}",
                                  style: TextStyle(
                                      color: Styles.textLightColor,
                                      fontSize: 12),
                                ),
                                TextButton(
                                    onPressed: () async {
                                      await _amountTopUpdated(
                                        toAmountDisplayBigInt(
                                            selectedToken.balance,
                                            decimals: selectedToken.decimals,
                                            fractionDigits:
                                                selectedToken.decimals),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(30, 10),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap),
                                    child: Text(
                                      "(Max)",
                                      style: TextStyle(
                                          color: Styles.blueColor,
                                          fontSize: 12),
                                    ))
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    const Gap(4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xffe1e2e8)),
                        borderRadius: BorderRadius.circular(12),
                        color: Styles.boxBackgroundColor,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              MaterialButton(
                                onPressed: () {
                                  showTokenSelectionModal(context,
                                      callback: _changeSelectedBottomToken);
                                },
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                minWidth: 0,
                                height: 36,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(
                                        color: Colors.black26)),
                                child: Row(
                                  children: [
                                    if (selectedBottomToken.iconUrl!.isNotEmpty)
                                      CachedNetworkImage(
                                        imageUrl:
                                            selectedBottomToken.iconUrl ?? "",
                                        width: 24,
                                        height: 24,
                                        placeholder: (context, url) =>
                                            Shimmer.fromColors(
                                          baseColor: Colors.grey[300]!,
                                          highlightColor: Colors.grey[350]!,
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            decoration: ShapeDecoration(
                                              color: Colors.grey[350]!,
                                              shape: const CircleBorder(),
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            const Icon(
                                          CupertinoIcons
                                              .exclamationmark_circle_fill,
                                          color: Colors.black12,
                                          size: 24,
                                        ),
                                      )
                                    else
                                      Icon(CupertinoIcons.question_circle,
                                          color: Colors.grey[600]!, size: 24),
                                    const Gap(4),
                                    Text(selectedBottomToken.symbol),
                                    const Gap(4),
                                    Icon(CupertinoIcons.chevron_down,
                                        size: 16, color: Styles.textLightColor)
                                  ],
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'[\.0-9]'))
                                    ],
                                    keyboardType: TextInputType.number,
                                    controller: amountBottomController,
                                    onChanged: (text) async {
                                      await _amountBottomUpdated(
                                          amountBottomController.text);
                                      // setState(() async {
                                      //you can access nameController in its scope to get
                                      // the value of text entered as shown below
                                      // selectedBottomToken.amount =
                                      //     amountBottomController.text;
                                      // });
                                    },
                                    decoration: InputDecoration(
                                        constraints:
                                            const BoxConstraints(maxHeight: 32),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                        enabledBorder: const OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.transparent),
                                        ),
                                        border: const OutlineInputBorder(),
                                        focusedBorder: const OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.transparent,
                                          ),
                                        ),
                                        hintText: '0.0',
                                        hintStyle: TextStyle(
                                            color: Styles.textLightColor)),
                                    textAlign: TextAlign.right),
                              ),
                            ],
                          ),
                          const Gap(8),
                          SizedBox(
                            width: double.infinity,
                            child: Row(
                              children: [
                                Text(
                                  "Balance: ${toAmountDisplayBigInt(
                                    selectedBottomToken.balance, decimals: selectedToken.decimals)} ${selectedBottomToken.symbol}",
                                  style: TextStyle(
                                      color: Styles.textLightColor,
                                      fontSize: 12),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    const Gap(8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40)),
                          shadowColor: const Color(0x559d6cff),
                          elevation: 5,
                          primary: (selectedToken.amount <= BigInt.zero ||
                                  selectedBottomToken.amount <= BigInt.zero)
                              ? const Color(0xff9d6cff)
                              : Styles.secondaryAccentColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () {
                          _executeSwap();
                        },
                        child: Text(
                          (selectedToken.amount <= BigInt.zero ||
                                  selectedBottomToken.amount <= BigInt.zero)
                              ? "Insert amount"
                              : "Confirm Send",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 96,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          width: 0.5, color: const Color(0xffe1e2e8)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x15000000),
                          blurRadius: 1,
                          offset: Offset(0, 1),
                        )
                      ],
                      color: Styles.boxBackgroundColor,
                    ),
                    height: 28,
                    width: 28,
                    child: Icon(CupertinoIcons.arrow_down,
                        size: 12, color: Styles.textLightColor),
                  ),
                ),
              ]),
        ],
      ),
    ));
  }
}
