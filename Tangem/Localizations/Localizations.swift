//
//  Localizations.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

/*struct Localizations {
    static let cancel = NSLocalizedString("general_cancel", comment: "Cancel")
    static let yes = NSLocalizedString("general_yes", comment: "Yes")
    static let no = NSLocalizedString("general_no", comment: "No")
    static let error = NSLocalizedString("general_error", comment: "Error!")
    static let noConnectionWithNodes = NSLocalizedString("general_error_no_connection", comment: "No connection with blockchain nodes")
    static let contin = NSLocalizedString("general_continue", comment: "Continue")
    static let errorEmptyPin = NSLocalizedString("error_empty_pin", comment: "PIN is empty")
    static let blockchain = NSLocalizedString("general_blockchain", comment: "Blockchain")
    static let tryScanAgain = NSLocalizedString("general_notification_scan_again", comment: "Try to scan again")
    static let eraseEmptyError = NSLocalizedString("general_error_cannot_erase_wallet_with_non_zero_balance", comment: "Cannot erase wallet with non-zero balance")
    static let sendPayment = NSLocalizedString("general_send_transaction", comment: "Send payment")
    static let fromBanknote = NSLocalizedString("general_from_banknote", comment: "From banknote")
    static let onBanknote = NSLocalizedString("general_on_banknote", comment: "on banknote")
    static let balance = NSLocalizedString("general_balance", comment: "with balance")
    static let sendToWallet = NSLocalizedString("general_send_to_wallet", comment: "Send to wallet")
    static let amount = NSLocalizedString("general_amount", comment: "Amount")
    static let btc = NSLocalizedString("general_btc", comment: "BTC")
    static let scanAgainToVerify = NSLocalizedString("general_notification_scan_again_to_verify", comment: "Scan again to verify the card")
    static let reading = NSLocalizedString("general_status_reading", comment: "READING…")
    static let emptyWallet = NSLocalizedString("general_wallet_empty", comment: "The wallet is empty")
}*/

// MARK: - Strings

class Localizations {
  /// Minimal
  static let confirmTransactionBtnFeeMinimal = translate("confirm_transaction_btn_fee_minimal")
  /// Normal
  static let confirmTransactionBtnFeeNormal = translate("confirm_transaction_btn_fee_normal")
  /// Priority
  static let confirmTransactionBtnFeePriority = translate("confirm_transaction_btn_fee_priority")
  /// Including fee
  static let confirmTransactionBtnIncludingFee = translate("confirm_transaction_btn_including_fee")
  /// Not including fee
  static let confirmTransactionBtnNotIncludingFee = translate("confirm_transaction_btn_not_including_fee")
  /// Send
  static let confirmTransactionBtnSend = translate("confirm_transaction_btn_send")
  /// Cannot calculate fee! Wrong data received from the node
  static let confirmTransactionErrorCannotCalculateFee = translate("confirm_transaction_error_cannot_calculate_fee")
  /// Cannot check balance! No connection with blockchain nodes
  static let confirmTransactionErrorCannotCheckBalance = translate("confirm_transaction_error_cannot_check_balance")
  /// Cannot reach current active blockchain node. Try again
  static let confirmTransactionErrorCannotReachNode = translate("confirm_transaction_error_cannot_reach_node")
  /// The obtained data is outdated! Try again
  static let confirmTransactionErrorDataIsOutdated = translate("confirm_transaction_error_data_is_outdated")
  /// Please wait for confirmation of incoming transaction
  static let confirmTransactionErrorIncomingTransactionUnconfirmed = translate("confirm_transaction_error_incoming_transaction_unconfirmed")
  /// Not enough ETH funds for fee
  static let confirmTransactionErrorNotEnoughEthForFee = translate("confirm_transaction_error_not_enough_eth_for_fee")
  /// Not enough RBTC funds for fee
  static let confirmTransactionErrorNotEnoughRbtcForFee = translate("confirm_transaction_error_not_enough_rbtc_for_fee")
  /// PIN2 is required to sign the payment
  static let confirmTransactionErrorPin2IsRequired = translate("confirm_transaction_error_pin_2_is_required")
  /// Service unavailable
  static let confirmTransactionErrorServiceUnavailable = translate("confirm_transaction_error_service_unavailable")
  /// Fee
  static let confirmTransactionFee = translate("confirm_transaction_fee")
  /// fee amount
  static let confirmTransactionHintFeeAmount = translate("confirm_transaction_hint_fee_amount")
  /// target wallet address
  static let confirmTransactionHintTargetAddress = translate("confirm_transaction_hint_target_address")
  /// (including fee)
  static let confirmTransactionIncludingFee = translate("confirm_transaction_including_fee")
  /// (not including fee)
  static let confirmTransactionNotIncludingFee = translate("confirm_transaction_not_including_fee")
  /// You have a risk of delaying transaction
  static let confirmTransactionWarningRiskDelaying = translate("confirm_transaction_warning_risk_delaying")
  /// From CRYPTONIT account:
  static let cryptonitFromAccount = translate("cryptonit_from_account")
  /// key:
  static let cryptonitKey = translate("cryptonit_key")
  /// nonce:
  static let cryptonitNonce = translate("cryptonit_nonce")
  /// Please enter account data
  static let cryptonitNotEnoughAccountData = translate("cryptonit_not_enough_account_data")
  /// password:
  static let cryptonitPassword = translate("cryptonit_password")
  /// CRYPTONIT payment
  static let cryptonitPayment = translate("cryptonit_payment")
  /// Get balance
  static let cryptonitRequestBalance = translate("cryptonit_request_balance")
  /// Withdrawal
  static let cryptonitRequestWithdrawal = translate("cryptonit_request_withdrawal")
  /// secret:
  static let cryptonitSecret = translate("cryptonit_secret")
  /// user ID:
  static let cryptonitUserId = translate("cryptonit_user_id")
  /// username:
  static let cryptonitUsername = translate("cryptonit_username")
  /// Attested
  static let detailsAttested = translate("details_attested")
  /// Card identity
  static let detailsCardIdentity = translate("details_card_identity")
  /// Issuer
  static let detailsCategoryIssuer = translate("details_category_issuer")
  /// Manufacturer
  static let detailsCategoryManufacturer = translate("details_category_manufacturer")
  /// Wallet
  static let detailsCategoryWallet = translate("details_category_wallet")
  /// Features
  static let detailsFeatures = translate("details_features")
  /// Firmware
  static let detailsFirmware = translate("details_firmware")
  /// This card is
  static let detailsIsCardReusable = translate("details_is_card_reusable")
  /// Last one!
  static let detailsLastOne = translate("details_last_one")
  /// None
  static let detailsNone = translate("details_none")
  /// not available
  static let detailsNotAvailable = translate("details_not_available")
  /// Not confirmed
  static let detailsNotConfirmed = translate("details_not_confirmed")
  /// One-off banknote
  static let detailsOneOffBanknote = translate("details_one_off_banknote")
  /// Possession NOT proved
  static let detailsPossessionNotProved = translate("details_possession_not_proved")
  /// Possession proved
  static let detailsPossessionProved = translate("details_possession_proved")
  /// Private key
  static let detailsPrivateKey = translate("details_private_key")
  /// This banknote is protected by default PIN1 code
  static let detailsProtectedByDefaultPin1 = translate("details_protected_by_default_pin_1")
  /// This banknote is protected by default PIN2 code
  static let detailsProtectedByDefaultPin2 = translate("details_protected_by_default_pin_2")
  /// This banknote is protected by user's PIN1 code
  static let detailsProtectedByUserPin1 = translate("details_protected_by_user_pin_1")
  /// This banknote is protected by user's PIN2 code
  static let detailsProtectedByUserPin2 = translate("details_protected_by_user_pin_2")
  /// Registration date
  static let detailsRegistrationDate = translate("details_registration_date")
  /// Remaining signatures
  static let detailsRemainingSignatures = translate("details_remaining_signatures")
  /// Reusable
  static let detailsReusable = translate("details_reusable")
  /// This banknote will enforce %.0f seconds security delay for all operations requiring PIN2 code
  static func detailsSecurityDelay(_ p1: Float) -> String {
    return translate("details_security_delay", p1)
  }
  /// Signed transactions
  static let detailsSignedTransactions = translate("details_signed_transactions")
  /// Signing method
  static let detailsSigningMethod = translate("details_signing_method")
  /// Time of last signing
  static let detailsTimeOfLastSigning = translate("details_time_of_last_signing")
  /// Card ID
  static let detailsTitleCardId = translate("details_title_card_id")
  /// Unlimited
  static let detailsUnlimited = translate("details_unlimited")
  /// Unlocked banknote, only for development use
  static let detailsUnlockedBanknote = translate("details_unlocked_banknote")
  /// Unspents
  static let detailsUnspents = translate("details_unspents")
  /// Validation node
  static let detailsValidationNode = translate("details_validation_node")
  /// Got it
  static let dialogBtnGotIt = translate("dialog_btn_got_it")
  /// Your Android device is rooted. Security at risk!
  static let dialogDeviceIsRooted = translate("dialog_device_is_rooted")
  /// Please hold the banknote firmly\n until the operation is completed…
  static let dialogHoldBanknote = translate("dialog_hold_banknote")
  /// Security delay
  static let dialogSecurityDelay = translate("dialog_security_delay")
  /// Oops.. It seems your smartphone does not support such long NFC packets.
  static let dialogTheNfcAdapterLengthApdu = translate("dialog_the_nfc_adapter_length_apdu")
  /// Try sending smaller amount or use a smartphone with full NFC support.
  static let dialogTheNfcAdapterLengthApduAdvice = translate("dialog_the_nfc_adapter_length_apdu_advice")
  /// This banknote has enforced security delay
  static let dialogThisBanknoteHasEnforcedSecurityDelay = translate("dialog_this_banknote_has_enforced_security_delay")
  /// Your money is at risk!
  static let dialogTitleMoneyIsAtRisk = translate("dialog_title_money_is_at_risk")
  /// Warning
  static let dialogWarning = translate("dialog_warning")
  /// You may be required to repeat this operation a few times depending on the NFC performance of your smartphone.\n This is made for safety of your funds.
  static let dialogYouMayBeRequiredToRepeat = translate("dialog_you_may_be_required_to_repeat")
  /// Create Wallet
  static let emptyWalletBtnCreate = translate("empty_wallet_btn_create")
  /// Wallet hasn't been yet created
  static let emptyWalletNotCreated = translate("empty_wallet_not_created")
  /// PIN is empty
  static let errorEmptyPin = translate("error_empty_pin")
  /// Amount
  static let generalAmount = translate("general_amount")
  /// with balance
  static let generalBalance = translate("general_balance")
  /// Blockchain
  static let generalBlockchain = translate("general_blockchain")
  /// BTC
  static let generalBtc = translate("general_btc")
  /// Cancel
  static let generalCancel = translate("general_cancel")
  /// Continue
  static let generalContinue = translate("general_continue")
  /// Error!
  static let generalError = translate("general_error")
  /// Cannot erase wallet with non-zero balance
  static let generalErrorCannotEraseWalletWithNonZeroBalance = translate("general_error_cannot_erase_wallet_with_non_zero_balance")
  /// No connection with blockchain nodes
  static let generalErrorNoConnection = translate("general_error_no_connection")
  /// From banknote
  static let generalFromBanknote = translate("general_from_banknote")
  /// No
  static let generalNo = translate("general_no")
  /// Try to scan again
  static let generalNotificationScanAgain = translate("general_notification_scan_again")
  /// Scan again to verify the card
  static let generalNotificationScanAgainToVerify = translate("general_notification_scan_again_to_verify")
  /// on banknote
  static let generalOnBanknote = translate("general_on_banknote")
  /// Send to wallet
  static let generalSendToWallet = translate("general_send_to_wallet")
  /// Send payment
  static let generalSendTransaction = translate("general_send_transaction")
  /// READING…
  static let generalStatusReading = translate("general_status_reading")
  /// The wallet is empty
  static let generalWalletEmpty = translate("general_wallet_empty")
  /// Yes
  static let generalYes = translate("general_yes")
  /// From KRAKEN account:
  static let krakenFromAccount = translate("kraken_from_account")
  /// key:
  static let krakenKey = translate("kraken_key")
  /// Please enter account data
  static let krakenNotEnoughAccountData = translate("kraken_not_enough_account_data")
  /// Operation canceled!
  static let krakenOperationCanceled = translate("kraken_operation_canceled")
  /// KRAKEN payment
  static let krakenPayment = translate("kraken_payment")
  /// Please confirm withdraw
  static let krakenPleaseConfirmWithdraw = translate("kraken_please_confirm_withdraw")
  /// Get balance
  static let krakenRequestBalance = translate("kraken_request_balance")
  /// Withdrawal
  static let krakenRequestWithdrawal = translate("kraken_request_withdrawal")
  /// secret:
  static let krakenSecret = translate("kraken_secret")
  /// Copy
  static let loadedWalletBtnCopy = translate("loaded_wallet_btn_copy")
  /// Details
  static let loadedWalletBtnDetails = translate("loaded_wallet_btn_details")
  /// Explore
  static let loadedWalletBtnExplore = translate("loaded_wallet_btn_explore")
  /// Extract
  static let loadedWalletBtnExtract = translate("loaded_wallet_btn_extract")
  /// Claim
  static let loadedWalletBtnClaim = translate("loaded_wallet_btn_claim")
  /// Load
  static let loadedWalletBtnLoad = translate("loaded_wallet_btn_load")
  /// New scan
  static let loadedWalletBtnNewScan = translate("loaded_wallet_btn_new_scan")
  /// Share wallet address with:
  static let loadedWalletChooserShare = translate("loaded_wallet_chooser_share")
  /// LOAD
  static let loadedWalletDialogShowQr = translate("loaded_wallet_dialog_show_qr")
  /// Cannot obtain data from blockchain (communication error)
  static let loadedWalletErrorBlockchainCommunicationError = translate("loaded_wallet_error_blockchain_communication_error")
  /// Cannot obtain data from blockchain (connection refused)
  static let loadedWalletErrorBlockchainConnectionRefused = translate("loaded_wallet_error_blockchain_connection_refused")
  /// Cannot obtain data from blockchain (empty answer received)
  static let loadedWalletErrorBlockchainEmptyAnswer = translate("loaded_wallet_error_blockchain_empty_answer")
  /// Cannot obtain data from blockchain
  static let loadedWalletErrorObtainingBlockchainData = translate("loaded_wallet_error_obtaining_blockchain_data")
  /// Another wallet app
  static let loadedWalletLoadViaApp = translate("loaded_wallet_load_via_app")
  /// via CRYPTONIT
  static let loadedWalletLoadViaCryptonit = translate("loaded_wallet_load_via_cryptonit")
  /// via CRYPTONIT2
  static let loadedWalletLoadViaCryptonit2 = translate("loaded_wallet_load_via_cryptonit2")
  /// via KRAKEN
  static let loadedWalletLoadViaKraken = translate("loaded_wallet_load_via_kraken")
  /// Show QR-code
  static let loadedWalletLoadViaQr = translate("loaded_wallet_load_via_qr")
  /// Share address
  static let loadedWalletLoadViaShareAddress = translate("loaded_wallet_load_via_share_address")
  /// Could not obtain all inputs. Swipe down to refresh.
  static let loadedWalletMessageRefresh = translate("loaded_wallet_message_refresh")
  /// Please wait while previous transaction is confirmed in blockchain
  static let loadedWalletMessageWait = translate("loaded_wallet_message_wait")
  /// No compatible wallets installed
  static let loadedWalletNoCompatibleWallet = translate("loaded_wallet_no_compatible_wallet")
  /// VERIFYING…
  static let loadedWalletStatusVerifying = translate("loaded_wallet_status_verifying")
  /// Copied to clipboard
  static let loadedWalletToastCopied = translate("loaded_wallet_toast_copied")
  /// Verifying in blockchain…
  static let loadedWalletVerifyingInBlockchain = translate("loaded_wallet_verifying_in_blockchain")
  /// Warning: This card has been already topped up and signed transactions in the past.\n        Consider immediate withdrawal of all funds if you have received this card from an untrusted source.
  static let loadedWalletWarningCardSignedTransactions = translate("loaded_wallet_warning_card_signed_transactions")
  /// If you use default PIN someone can steal your money!
  static let loadedWalletWarningDefaultPin = translate("loaded_wallet_warning_default_pin")
  /// If you forget your new PIN you will lose your money forever!
  static let loadedWalletWarningDontForgetPin = translate("loaded_wallet_warning_dont_forget_pin")
  /// Card has no remaining signature!
  static let loadedWalletWarningNoSignature = translate("loaded_wallet_warning_no_signature")
  /// About…
  static let mainMenuAbout = translate("main_menu_about")
  /// Send logs…
  static let mainMenuDebugSendLogs = translate("main_menu_debug_send_logs")
  /// Manage user PIN1…
  static let mainMenuManagePin1 = translate("main_menu_manage_pin_1")
  /// Manage user PIN2…
  static let mainMenuManagePin2 = translate("main_menu_manage_pin_2")
  /// Update
  static let mainScreenBtnUpdate = translate("main_screen_btn_update")
  /// Wallet was erased
  static let mainScreenErasedWallet = translate("main_screen_erased_wallet")
  /// There is a new application version: %@
  static func mainScreenNewVersionToast(_ p1: String) -> String {
    return translate("main_screen_new_version_toast", p1)
  }
  /// Not personalized
  static let mainScreenNotPersonalized = translate("main_screen_not_personalized")
  /// phone
  static let mainScreenPhone = translate("main_screen_phone")
  /// Scan a banknote with your \n %@ \n as shown above
  static func mainScreenScanBanknote(_ p1: String) -> String {
    return translate("main_screen_scan_banknote", p1)
  }
  /// Tap Tangem card with your smartphone
  static let mainScreenTapCard = translate("main_screen_tap_card")
  /// Erase wallet
  static let menuLoadedWalletEraseWallet = translate("menu_loaded_wallet_erase_wallet")
  /// Reset PIN1 to default
  static let menuLoadedWalletResetPin1 = translate("menu_loaded_wallet_reset_pin_1")
  /// Reset PIN2 to default
  static let menuLoadedWalletResetPin2 = translate("menu_loaded_wallet_reset_pin_2")
  /// Reset PINs to default
  static let menuLoadedWalletResetPins = translate("menu_loaded_wallet_reset_pins")
  /// Set PIN1
  static let menuLoadedWalletSetPin1 = translate("menu_loaded_wallet_set_pin_1")
  /// Set PIN2
  static let menuLoadedWalletSetPin2 = translate("menu_loaded_wallet_set_pin_2")
  /// Cannot create wallet. Make sure you enter correct PIN2!
  static let nfcErrorCannotCreateWallet = translate("nfc_error_cannot_create_wallet")
  /// Cannot erase wallet. Make sure you enter correct PIN2!
  static let nfcErrorCannotEraseWallet = translate("nfc_error_cannot_erase_wallet")
  /// By tapping the card, you will permanently remove the blockchain wallet. Ensure there will be no further incoming transactions
  static let nfcPurgeWarning = translate("nfc_purge_warning")
  /// Now touch the banknote with ID
  static let nowTouchTheBanknoteWithId = translate("now_touch_the_banknote_with_id")
  /// Confirm new PIN
  static let pinRequestConfirmNewPin = translate("pin_request_confirm_new_pin")
  /// Confirm new PIN2
  static let pinRequestConfirmNewPin2 = translate("pin_request_confirm_new_pin_2")
  /// Enter new PIN
  static let pinRequestEnterNewPin = translate("pin_request_enter_new_pin")
  /// Enter new PIN or use fingerprint scanner
  static let pinRequestEnterNewPinOrUseFingerprintScanner = translate("pin_request_enter_new_pin_or_use_fingerprint_scanner")
  /// Enter PIN
  static let pinRequestEnterPin = translate("pin_request_enter_pin")
  /// Enter PIN2 or use fingerprint scanner
  static let pinRequestEnterPin2OrUseFingerprintScanner = translate("pin_request_enter_pin_2_or_use_fingerprint_scanner")
  /// Enter PIN or use fingerprint scanner
  static let pinRequestEnterPinOrUseFingerprintScanner = translate("pin_request_enter_pin_or_use_fingerprint_scanner")
  /// Please enter the PIN for confirmation!
  static let pinRequestErrorPinConfirmationFailed = translate("pin_request_error_pin_confirmation_failed")
  /// Enter new PIN2
  static let pinRequestNewPin2 = translate("pin_request_new_pin_2")
  /// Enter PIN2
  static let pinRequestPromptEnterPin2 = translate("pin_request_prompt_enter_pin_2")
  /// Enter new PIN2 or use fingerprint scanner
  static let pinRequestPromptNewPin2OrFingerprint = translate("pin_request_prompt_new_pin_2_or_fingerprint")
  /// Delete
  static let pinSaveBtnDelete = translate("pin_save_btn_delete")
  /// Save
  static let pinSaveBtnSave = translate("pin_save_btn_save")
  /// Protect with fingerprint
  static let pinSaveCheckboxProtectWithFingerprint = translate("pin_save_checkbox_protect_with_fingerprint")
  /// Touch fingerprint scanner to confirm
  static let pinSaveDialogTouchFingerprintScanner = translate("pin_save_dialog_touch_fingerprint_scanner")
  /// Saving pin failed
  static let pinSaveNotificationFailed = translate("pin_save_notification_failed")
  /// Enter PIN2 and save it
  static let pinSaveTitleEnterPin2AndSave = translate("pin_save_title_enter_pin2_and_save")
  /// Enter PIN and save it
  static let pinSaveTitleEnterPinAndSave = translate("pin_save_title_enter_pin_and_save")
  /// User hasn't enabled Lock Screen
  static let pinSaveToastLockScreenNotEnabled = translate("pin_save_toast_lock_screen_not_enabled")
  /// User hasn't registered any fingerprints
  static let pinSaveToastNoFingerprintsRegistered = translate("pin_save_toast_no_fingerprints_registered")
  /// User hasn't granted permission to use Fingerprint
  static let pinSaveToastNoPermissionToUseFingerprint = translate("pin_save_toast_no_permission_to_use_fingerprint")
  /// Verify
  static let prepareTransactionBtnVerify = translate("prepare_transaction_btn_verify")
  /// Amount is empty
  static let prepareTransactionErrorAmountEmpty = translate("prepare_transaction_error_amount_empty")
  /// Incorrect destination wallet address
  static let prepareTransactionErrorIncorrectDestination = translate("prepare_transaction_error_incorrect_destination")
  /// Not enough funds
  static let prepareTransactionErrorNotEnoughFunds = translate("prepare_transaction_error_not_enough_funds")
  /// Destination wallet address equal source address
  static let prepareTransactionErrorSameAddress = translate("prepare_transaction_error_same_address")
  /// Unknown amount format
  static let prepareTransactionErrorUnknownAmountFormat = translate("prepare_transaction_error_unknown_amount_format")
  /// enter wallet address
  static let prepareTransactionHintEnterAddress = translate("prepare_transaction_hint_enter_address")
  /// enter amount
  static let prepareTransactionHintEnterAmount = translate("prepare_transaction_hint_enter_amount")
  /// Cannot sign transaction. Make sure you enter correct PIN2!
  static let sendTransactionErrorCannotSign = translate("send_transaction_error_cannot_sign")
  /// Try again. Failed to send transaction (%@)
  static func sendTransactionErrorFailedToSend(_ p1: String) -> String {
    return translate("send_transaction_error_failed_to_send", p1)
  }
  /// Amount and fee exceed total wallet balance!
  static let sendTransactionErrorWrongAmount = translate("send_transaction_error_wrong_amount")
  /// Please wait while the payment is sent…
  static let sendTransactionNotificationWait = translate("send_transaction_notification_wait")
  /// Transaction has been successfully signed and sent to blockchain node. Wallet balance will be updated in a while
  static let sendTransactionSuccess = translate("send_transaction_success")
  /// Common
  static let settingsCategorySommon = translate("settings-category-sommon")
  /// 0
  static let settingsEncryptionModeValues0 = translate("settings_encryption_mode_values[0]")
  /// 1
  static let settingsEncryptionModeValues1 = translate("settings_encryption_mode_values[1]")
  /// 2
  static let settingsEncryptionModeValues2 = translate("settings_encryption_mode_values[2]")
  /// None
  static let settingsEncryptionModesEntries0 = translate("settings_encryption_modes_entries[0]")
  /// Fast
  static let settingsEncryptionModesEntries1 = translate("settings_encryption_modes_entries[1]")
  /// Strong
  static let settingsEncryptionModesEntries2 = translate("settings_encryption_modes_entries[2]")
  /// Encryption modes
  static let settingsOptionEncryptionModes = translate("settings_option_encryption_modes")
  /// Manual editing Fee
  static let settingsOptionManualEditingFee = translate("settings_option_manual_editing_fee")
  /// Select nodes
  static let settingsOptionSelectNodes = translate("settings_option_select_nodes")
  /// Settings
  static let settingsTitle = translate("settings_title")
  /// Cardano
  static let splashCardano = translate("splash_cardano")
  /// ALPHA v.%1$@ \n dev \n build %2$@
  static func splashVersionNameDebug(_ p1: String, _ p2: String) -> String {
    return translate("splash_version_name_debug", p1, p2)
  }
  /// v.%@
  static func splashVersionNameRelease(_ p1: String) -> String {
    return translate("splash_version_name_release", p1)
  }
  /// to change PIN/PIN2 codes
  static let toChangePinCodes = translate("to_change_pin_codes")
  /// to create the wallet
  static let toCreateTheWallet = translate("to_create_the_wallet")
  /// to erase the wallet
  static let toEraseTheWallet = translate("to_erase_the_wallet")
  /// to sign the payment
  static let toSignTheTransaction = translate("to_sign_the_transaction")
  /// operation fee
  static let withdrawalFee = translate("withdrawal_fee")
  /// Withdrawal successful!
  static let withdrawalSuccessful = translate("withdrawal_successful")
    
  // MARK: - IOS
    
    static let verifiedBalance = translate("common_verified_balance")
    static let verifiedTag = translate("common_verified_tag")
    static let unverifiedBalance = translate("common_unverified_balance")
    static let disclamerNoWalletCreation = translate("disclamer_no_wallet_creation")
    
    static let disclamerNfcTitle = translate("disclamer_nfc_title")
    static let disclamerNfcMessage = translate("disclamer_nfc_message")
    static let disclamerNfcOk = translate("disclamer_nfc_understand")
    static let disclamerNfcNotShow = translate("disclamer_nfc_notshow")
    static let moreInfo = translate("common_more_info")
    static let ok = translate("common_ok")
    static let success = translate("common_success")
    static let alertParseFailed = translate("alert_parse_failed")
    static let alertReadProtected = translate("alert_read_protected")
    static let alertNfcGeneric = translate("alert_nfc_generic")
    static let alertFailedAttest = translate("alert_failed_attest")
    static let alertUnknownBlockchain = translate("alert_unknown_blockchain")
    static let alertNoIssuerSign = translate("alert_no_issuer_sign")
    static let alertFailedBuildTx = translate("alert_failed_build_transaction")
    static let readerHintDefault = translate("reader_hint_label_default")
    static let readerHintScan = translate("reader_hint_label_scan")
    static let scanButtonTitle = translate("common_scan_button_title")
    static let readerStubNfcMessage = translate("reader_nfc_stub_message")
    static let addressCopied = translate("common_address_copied")
    static let copyAddress = translate("common_copy_address")
    static let disclamerOldCard = translate("disclamer_old_card")
    static let disclamerOldIOS = translate("disclamer_old_ios")
    static let test = translate("common_test")
    static let signatureVerificationError = translate("signature_verification_error")
    static let testBlockchain = translate("common_test_blockchain")
    static let reserve = translate("common_reserve")
    static let tapToRetry = translate("common_tap_to_retry")
    static let genuine = translate("common_genuine")
    static let notgenuine = translate("common_not_genuine")
    static let alreadyClaimed = translate("already_claimed")
    static let notFound = translate("common_not_found")
    static let copied = translate("common_copied")
    static let signature = translate("common_signature")
    static let challenge = translate("common_challenge")
    static let passed = translate("common_passed")
    static let notPassed = translate("common_not_passed")
    static let notAvailable = translate("common_not_available")
    static let commonFeeStub = translate("common_fee_stub")
    static let sendPayment = translate("common_send_payment")
    static let address = translate("common_address")
    static let toWallet = translate("common_to_wallet")
    static let doubleScanHint = translate("common_double_scan_hint")
    static let alertStart2CoinMessage = translate("alert_start2coin")
    static let goToLink = translate("common_go_link")
    static let detailsLinkedCard = translate("details_linked_card_title")
    static let commonNext = translate("common_next")
    static let storeTitle = translate("main_store_title")
    static let storeSubtitle = translate("main_store_subtitle")
    static let oldDeviceForThisCard = translate("old_device_this_card")
    static let accountNotFound = translate("balance_validator_first_line_account_not_found")
    static let loadMoreXrpToCreateAccount = translate("balance_validator_second_line_create_account_xrp")
    static let lastSignature = translate("last_sig")
    static let unknownCardState = translate("nfc_unknown_card_state")
    static let nfcAlertSignCompleted = translate("nfc_alert_sign_completed")
    static let nfcSessionTimeout = translate("nfc_session_timeout")
    static let nfcAlertDefault = translate("nfc_alert_default")
    static let nfcStuckError = translate("nfc_stuck_error")
    static let slixFailedToParse = "Failed to read the Tag"
    static let xlmCreateAccountHint = translate("balance_validator_second_line_create_account_instruction")
    static let xlmAssetCreateAccountHint = translate("balance_validator_second_line_create_account_instruction_asset")
    static func secondsLeft(_ p1: String) -> String {
        return translate("nfc_seconds_left", p1)
    }
}
// MARK: - Implementation Details

extension Localizations {
  private static func translate( _ key: String, _ args: CVarArg...) -> String {
    let format = NSLocalizedString(key, comment: "")
    return String(format: format, locale: Locale.current, arguments: args).replacingOccurrences(of: "()", with: "")
  }
}
