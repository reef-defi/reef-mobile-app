import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:reef_mobile_app/components/modal.dart';
import 'package:reef_mobile_app/model/ReefAppState.dart';
import 'package:reef_mobile_app/model/StorageKey.dart';
import 'package:reef_mobile_app/model/account/stored_account.dart';
import 'package:reef_mobile_app/service/StorageService.dart';
import 'package:reef_mobile_app/utils/elements.dart';
import 'package:reef_mobile_app/utils/functions.dart';
import 'package:reef_mobile_app/utils/styles.dart';
import 'package:flutter/services.dart';

class AccountCreationContent extends StatefulWidget {
  final VoidCallback next;
  final StoredAccount? account;
  const AccountCreationContent(
      {Key? key, required this.next, required this.account})
      : super(key: key);

  @override
  State<AccountCreationContent> createState() => _AccountCreationContentState();
}

class _AccountCreationContentState extends State<AccountCreationContent> {
  bool _isEditingText = false;
  late TextEditingController _editingController;
  late String initialText;

  bool _checkedValue = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      if (widget.account != null) {
        if (widget.account?.name.isEmpty as bool) {
          initialText = "<No Name>";
        } else {
          initialText = widget.account?.name as String;
        }
      } else {
        initialText = "<No Name>";
      }
    });
    _editingController = TextEditingController(text: initialText);
    _editingController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _editingController.value.text.length,
    );
  }

  @override
  void dispose() {
    _editingController.dispose();
    super.dispose();
  }

  Widget _editTitleTextField() {
    if (_isEditingText) {
      return IntrinsicWidth(
        child: TextField(
          controller: _editingController,
          autofocus: true,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration.collapsed(hintText: initialText),
          onSubmitted: (newValue) {
            setState(() {
              if (newValue.isNotEmpty) {
                initialText = newValue;
                widget.account?.name = newValue;
              }
              _isEditingText = false;
            });
          },
        ),
      );
    }
    return InkWell(
        onTap: () {
          setState(() {
            _isEditingText = true;
          });
        },
        child: Text(initialText,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Styles.textColor)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 0, left: 24, bottom: 24, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ViewBoxContainer(
              color: Styles.whiteColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 24.0, horizontal: 16.0),
                child:
                 ClipRect(
                   child: Row(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black12,
                        ),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(64),
                            child: (widget.account?.svg != null)
                                ? SvgPicture.string(widget.account?.svg as String)
                                : Container(
                                    width: 64,
                                    height: 64,
                                    decoration:
                                        BoxDecoration(color: Colors.grey[600]!),
                                  )),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _editTitleTextField(),
                                const Gap(2),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                  icon: Icon(Icons.edit,
                                      size: 14, color: Colors.grey[600]!),
                                  onPressed: () {
                                    setState(() {
                                      _isEditingText = true;
                                    });
                                  },
                                )
                              ],
                            ),
                            const Gap(2),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Address: ${widget.account?.address.shorten() ?? "Loading..."}",
                                    style: TextStyle(color: Colors.grey[600]!),
                                    overflow: TextOverflow.fade,
                                    maxLines: 1,
                                    softWrap: false
                                  ),
                                ),
                                const Gap(2),
                                IconButton(
                                  constraints: BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  icon: Icon(Icons.copy, size: 12),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(
                                        text: widget.account?.address));
                                  },
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                ),
                 ),
              )),
          const Gap(12),
          Text(
            "GENERATED 12-WORD MNEMONIC SEED:",
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Styles.textLightColor),
          ),
          const Gap(8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Styles.whiteColor,
              border: Border.all(
                color: const Color(0x20000000),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x16000000),
                  blurRadius: 24,
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                widget.account?.mnemonic ?? "Loading...",
                style: TextStyle(color: Styles.primaryAccentColorDark),
              ),
            ),
          ),
          const Gap(4),
          TextButton(
              style: TextButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              onPressed: () {
                if (widget.account?.mnemonic != null) {
                  Clipboard.setData(
                      ClipboardData(text: widget.account?.mnemonic));
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.copy,
                    size: 12,
                    color: Styles.textLightColor,
                  ),
                  const Gap(2),
                  Text(
                    "Copy to clipboard",
                    style: TextStyle(color: Styles.textColor, fontSize: 12),
                  ),
                ],
              )),
          const Gap(12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                color: Styles.primaryAccentColorDark,
              ),
              const Gap(8),
              Flexible(
                child: Text(
                  "Please write down your wallet's mnemonic seed and keep it in a safe place. The mnemonic can be used to restore your wallet. Keep it carefully to not lose your assets.",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),
            ],
          ),
          const Gap(8),
          Row(
            children: [
              Checkbox(
                visualDensity:
                    const VisualDensity(horizontal: -4, vertical: -4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                fillColor: MaterialStateProperty.all<Color>(Colors.grey[800]!),
                value: _checkedValue,
                onChanged: (bool? value) {
                  setState(() {
                    _checkedValue = value ?? false;
                  });
                },
              ),
              const Gap(8),
              Flexible(
                child: Text(
                  "I have saved my mnemonic seed safely.",
                  style: TextStyle(color: Colors.grey[600]!, fontSize: 14),
                ),
              )
            ],
          ),
          const Gap(16),
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    splashFactory: !_checkedValue
                        ? NoSplash.splashFactory
                        : InkSplash.splashFactory,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40)),
                    shadowColor: const Color(0x559d6cff),
                    elevation: 5,
                    primary: !_checkedValue
                        ? const Color(0xff9d6cff)
                        : Styles.secondaryAccentColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    if (_checkedValue) widget.next();
                  },
                  child: const Text(
                    'Next Step',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                  child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(Icons.arrow_forward,
                      color: Styles.whiteColor, size: 20),
                ),
              ))
            ],
          ),
        ],
      ),
    );
  }
}

class AccountCreationConfirmContent extends StatefulWidget {
  final VoidCallback prev;
  final StoredAccount? account;
  final Future<dynamic> Function(StoredAccount) saveAccount;
  const AccountCreationConfirmContent(
      {Key? key,
      required this.prev,
      required this.account,
      required this.saveAccount})
      : super(key: key);

  @override
  State<AccountCreationConfirmContent> createState() =>
      _AccountCreationConfirmContentState();
}

class _AccountCreationConfirmContentState
    extends State<AccountCreationConfirmContent> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late String name;
  String password = "";
  bool _hasPassword = false;
  final chains = <String>[
    'Allow use on any chain',
    'Reef Chain',
    'Polkadot Relay Chain',
    'Kusama Relay Chain',
    'Karura',
  ];

  String selectedChain = 'Allow use on any chain';

  @override
  void initState() {
    super.initState();
    setState(() {
      if (widget.account != null) {
        if (widget.account?.name.isEmpty as bool) {
          name = "<No Name>";
        } else {
          name = widget.account?.name as String;
        }
      } else {
        name = "<No Name>";
      }
    });
    _nameController.text = name == "<No Name>" ? "" : name;
    _nameController.addListener(() {
      setState(() {
        name = _nameController.text;
        widget.account?.name = name;
      });
    });
    _passwordController.addListener(() {
      setState(() {
        password = _passwordController.text;
      });
    });
    ReefAppState.instance.storage
        .getValue(StorageKey.password.name)
        .then((value) => setState(() {
              _hasPassword = value != null && value.isNotEmpty;
            }));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 0, left: 24, bottom: 24, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ViewBoxContainer(
              color: Styles.whiteColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 24.0, horizontal: 16.0),
                child: Row(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black12,
                      ),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(64),
                          child: (widget.account?.svg != null)
                              ? SvgPicture.string(widget.account?.svg as String)
                              : Container(
                                  width: 64,
                                  height: 64,
                                  decoration:
                                      BoxDecoration(color: Colors.grey[600]!),
                                )),
                    ),
                    const Gap(12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Gap(2),
                        Row(
                          children: [
                            Text(
                              "Address: ${widget.account?.address.shorten() ?? "Loading..."}",
                              style: TextStyle(color: Colors.grey[600]!),
                            ),
                            const Gap(2),
                            IconButton(
                              constraints: BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: Icon(Icons.copy, size: 12),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(
                                    text: widget.account?.address));
                              },
                            )
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              )),
          const Gap(12),
          Text(
            "NETWORK",
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Styles.textLightColor),
          ),
          const Gap(8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Styles.whiteColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0x20000000),
                width: 1,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: selectedChain,
                items: chains.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedChain = newValue!;
                  });
                },
              ),
            ),
          ),
          const Gap(8),
          Text(
            "A DESCRIPTIVE NAME FOR YOUR ACCOUNT",
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Styles.textLightColor),
          ),
          const Gap(8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Styles.whiteColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0x20000000),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration.collapsed(hintText: ''),
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
          const Gap(8),
          if (!_hasPassword) ...[
            Text(
              "A PASSWORD FOR REEF APP",
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Styles.textLightColor),
            ),
            const Gap(8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Styles.whiteColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0x20000000),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration.collapsed(hintText: ''),
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ],
          const Gap(24),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            width: double.infinity,
            child: Row(
              children: [
                TextButton(
                    onPressed: () {
                      widget.prev();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black12,
                      minimumSize: const Size(48, 48),
                      padding: EdgeInsets.zero,
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: Styles.textColor,
                      size: 20,
                    )),
                const Gap(4),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      splashFactory: !(name.isNotEmpty &&
                              (!_hasPassword || password.isNotEmpty))
                          ? NoSplash.splashFactory
                          : InkSplash.splashFactory,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40)),
                      shadowColor: const Color(0x559d6cff),
                      elevation: 5,
                      backgroundColor: (name.isNotEmpty &&
                              (!_hasPassword || password.isNotEmpty))
                          ? Styles.secondaryAccentColor
                          : const Color(0xff9d6cff),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      if (name.isNotEmpty &&
                          (_hasPassword || password.isNotEmpty)) {
                        if (widget.account != null) {
                          widget.saveAccount(widget.account as StoredAccount);
                          if (password.isNotEmpty) {
                            ReefAppState.instance.storage
                                .setValue(StorageKey.password.name, password);
                          }
                          print(
                              "Saved account with name: ${widget.account?.name} and address: ${widget.account?.address}");
                          Navigator.of(context).pop();
                        }
                      }
                    },
                    child: const Text(
                      'Add the account with generated seed',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    ;
  }
}

class CurrentScreen extends StatefulWidget {
  CurrentScreen({Key? key}) : super(key: key);

  final ReefAppState reefState = ReefAppState.instance;
  final StorageService storageService = ReefAppState.instance.storage;

  @override
  State<CurrentScreen> createState() => _CurrentScreenState();
}

class _CurrentScreenState extends State<CurrentScreen> {
  int activeIndex = 0;
  StoredAccount? account;

  void generateAccount() async {
    var response = await widget.reefState.accountCtrl.generateAccount();
    var generatedAccount = StoredAccount.fromString(response);
    print("Mnemonic: ${generatedAccount.mnemonic}");
    print("Name: ${generatedAccount.name}");
    print("Address: ${generatedAccount.address}");
    setState(() {
      account = generatedAccount;
    });
  }

  Future saveAccount(StoredAccount account) async {
    await ReefAppState.instance.accountCtrl.saveAccount(account);
  }

  nextIndex() {
    setState(() {
      activeIndex = 1;
    });
  }

  prevIndex() {
    setState(() {
      activeIndex = 0;
    });
  }

  List<Widget> content = [];

  @override
  void initState() {
    super.initState();
    generateAccount();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutExpo,
      switchOutCurve: Curves.easeInExpo,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(-1.0, 0.0),
              end: const Offset(0.0, 0.0),
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: (activeIndex == 0)
          ? AccountCreationContent(next: nextIndex, account: account)
          : AccountCreationConfirmContent(
              prev: prevIndex, account: account, saveAccount: saveAccount),
    );
  }
}

void showCreateAccountModal(BuildContext context) {
  showModal(context,
      headText: "Create Account", dismissible: true, child: CurrentScreen());
}
