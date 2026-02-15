// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import SwiftUI

// MARK: - Strings

/// Why `Localization`?
/// https://en.wikipedia.org/wiki/Internationalization_and_localization
public enum Localization {
  /// Without an access code, your wallet is not secure.
  public static let accessCodeAlertSkipDescription = Localization.tr("Localizable", "access_code_alert_skip_description")
  /// Skip anyway
  public static let accessCodeAlertSkipOk = Localization.tr("Localizable", "access_code_alert_skip_ok")
  /// Access code not set
  public static let accessCodeAlertSkipTitle = Localization.tr("Localizable", "access_code_alert_skip_title")
  /// Change code
  public static let accessCodeAlertValidationCancel = Localization.tr("Localizable", "access_code_alert_validation_cancel")
  /// Your access code unlocks and protects access to your wallet
  public static let accessCodeAlertValidationDescription = Localization.tr("Localizable", "access_code_alert_validation_description")
  /// Use anyway
  public static let accessCodeAlertValidationOk = Localization.tr("Localizable", "access_code_alert_validation_ok")
  /// This access code can be easily guessed
  public static let accessCodeAlertValidationTitle = Localization.tr("Localizable", "access_code_alert_validation_title")
  /// Enter access code
  public static let accessCodeCheckTitle = Localization.tr("Localizable", "access_code_check_title")
  /// Wrong access code. Your mobile wallet will be deleted after %@ more incorrect attempts.
  public static func accessCodeCheckWariningDelete(_ p1: Any) -> String {
    return Localization.tr("Localizable", "access_code_check_warining_delete", String(describing: p1))
  }
  /// Wrong access code. The app will be locked after %@ more failed attempts
  public static func accessCodeCheckWariningLock(_ p1: Any) -> String {
    return Localization.tr("Localizable", "access_code_check_warining_lock", String(describing: p1))
  }
  /// Wrong access code.\nPlease wait %@ seconds and try again.
  public static func accessCodeCheckWariningWait(_ p1: Any) -> String {
    return Localization.tr("Localizable", "access_code_check_warining_wait", String(describing: p1))
  }
  /// Confirm your access code to continue
  public static let accessCodeConfirmDescription = Localization.tr("Localizable", "access_code_confirm_description")
  /// Re-enter access code
  public static let accessCodeConfirmTitle = Localization.tr("Localizable", "access_code_confirm_title")
  /// Set a %@-digit access code to unlock your wallet.
  public static func accessCodeCreateDescription(_ p1: Any) -> String {
    return Localization.tr("Localizable", "access_code_create_description", String(describing: p1))
  }
  /// Create access code
  public static let accessCodeCreateTitle = Localization.tr("Localizable", "access_code_create_title")
  /// Access code
  public static let accessCodeNavtitle = Localization.tr("Localizable", "access_code_navtitle")
  /// Long press
  public static let accessibilityActionLongPress = Localization.tr("Localizable", "accessibility_action_long_press")
  /// Swipe up or down to access more actions
  public static let accessibilityHintAccessMoreActions = Localization.tr("Localizable", "accessibility_hint_access_more_actions")
  /// You cannot create more than %1$@ accounts. Archive one to add new.
  public static func accountAddLimitDialogDescription(_ p1: Any) -> String {
    return Localization.tr("Localizable", "account_add_limit_dialog_description", String(describing: p1))
  }
  /// Can’t add new account
  public static let accountAddLimitDialogTitle = Localization.tr("Localizable", "account_add_limit_dialog_title")
  /// Account archived
  public static let accountArchiveSuccessMessage = Localization.tr("Localizable", "account_archive_success_message")
  /// Archived accounts
  public static let accountArchivedAccounts = Localization.tr("Localizable", "account_archived_accounts")
  /// Recover
  public static let accountArchivedRecover = Localization.tr("Localizable", "account_archived_recover")
  /// Can't recover account
  public static let accountArchivedRecoverErrorTitle = Localization.tr("Localizable", "account_archived_recover_error_title")
  /// Archived
  public static let accountArchivedTitle = Localization.tr("Localizable", "account_archived_title")
  /// We couldn’t archive account. Please try again later.
  public static let accountCouldNotArchive = Localization.tr("Localizable", "account_could_not_archive")
  /// This account is participating in the referral program.
  public static let accountCouldNotArchiveReferralProgramMessage = Localization.tr("Localizable", "account_could_not_archive_referral_program_message")
  /// This account can’t be archived
  public static let accountCouldNotArchiveReferralProgramTitle = Localization.tr("Localizable", "account_could_not_archive_referral_program_title")
  /// We couldn’t create account. Please try again later.
  public static let accountCouldNotCreate = Localization.tr("Localizable", "account_could_not_create")
  /// Account created
  public static let accountCreateSuccessMessage = Localization.tr("Localizable", "account_create_success_message")
  /// Archive account
  public static let accountDetailsArchive = Localization.tr("Localizable", "account_details_archive")
  /// You are archiving this account, but you can always get it back.
  public static let accountDetailsArchiveDescription = Localization.tr("Localizable", "account_details_archive_description")
  /// Archiving...
  public static let accountDetailsArchiving = Localization.tr("Localizable", "account_details_archiving")
  /// Account
  public static let accountDetailsTitle = Localization.tr("Localizable", "account_details_title")
  /// Account saved
  public static let accountEditSuccessMessage = Localization.tr("Localizable", "account_edit_success_message")
  /// Account for rewards
  public static let accountForRewards = Localization.tr("Localizable", "account_for_rewards")
  /// Account #%@ — used for address derivation.
  public static func accountFormAccountIndex(_ p1: Any) -> String {
    return Localization.tr("Localizable", "account_form_account_index", String(describing: p1))
  }
  /// Add account
  public static let accountFormCreateButton = Localization.tr("Localizable", "account_form_create_button")
  /// Save
  public static let accountFormEditButton = Localization.tr("Localizable", "account_form_edit_button")
  /// Account name
  public static let accountFormName = Localization.tr("Localizable", "account_form_name")
  /// An account with this name already exists. Please choose a different name.
  public static let accountFormNameAlreadyExistErrorDescription = Localization.tr("Localizable", "account_form_name_already_exist_error_description")
  /// Account name already in use
  public static let accountFormNameAlreadyExistErrorTitle = Localization.tr("Localizable", "account_form_name_already_exist_error_title")
  /// Account
  public static let accountFormPlaceholderEditAccount = Localization.tr("Localizable", "account_form_placeholder_edit_account")
  /// New account
  public static let accountFormPlaceholderNewAccount = Localization.tr("Localizable", "account_form_placeholder_new_account")
  /// Add account
  public static let accountFormTitleCreate = Localization.tr("Localizable", "account_form_title_create")
  /// Edit account
  public static let accountFormTitleEdit = Localization.tr("Localizable", "account_form_title_edit")
  /// Please try again later. If the problem persists, contact support and we’ll help you resolve it.
  public static let accountGenericErrorDialogMessage = Localization.tr("Localizable", "account_generic_error_dialog_message")
  /// %1$@ in %2$@
  public static func accountLabelTokensInfo(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "account_label_tokens_info", String(describing: p1), String(describing: p2))
  }
  /// Main account
  public static let accountMainAccountTitle = Localization.tr("Localizable", "account_main_account_title")
  /// You have already exceeded the limit of %1$@ active accounts. Archive one to recover
  public static func accountRecoverLimitDialogDescription(_ p1: Any) -> String {
    return Localization.tr("Localizable", "account_recover_limit_dialog_description", String(describing: p1))
  }
  /// Account recovered
  public static let accountRecoverSuccessMessage = Localization.tr("Localizable", "account_recover_success_message")
  /// Long tap on an account to reorder accounts
  public static let accountReorderDescription = Localization.tr("Localizable", "account_reorder_description")
  /// Keep Editing
  public static let accountUnsavedDialogActionFirst = Localization.tr("Localizable", "account_unsaved_dialog_action_first")
  /// Discard
  public static let accountUnsavedDialogActionSecond = Localization.tr("Localizable", "account_unsaved_dialog_action_second")
  /// Are you sure you want to discard new account?
  public static let accountUnsavedDialogMessageCreate = Localization.tr("Localizable", "account_unsaved_dialog_message_create")
  /// Are you sure you want to discard edits?
  public static let accountUnsavedDialogMessageEdit = Localization.tr("Localizable", "account_unsaved_dialog_message_edit")
  /// Unsaved Changes
  public static let accountUnsavedDialogTitle = Localization.tr("Localizable", "account_unsaved_dialog_title")
  /// Some custom tokens will be automatically moved from “%1$@” to “%2$@” as their derivation belongs to that account.
  public static func accountsMigrationAlertMessage(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "accounts_migration_alert_message", String(describing: p1), String(describing: p2))
  }
  /// Some custom tokens will be automatically moved
  public static let accountsMigrationAlertTitle = Localization.tr("Localizable", "accounts_migration_alert_title")
  /// Can’t find your token? Go to the Market section on the main page and add it to your portfolio for purchase
  public static let actionButtonsBuyEmptySearchMessage = Localization.tr("Localizable", "action_buttons_buy_empty_search_message")
  /// Buy
  public static let actionButtonsBuyNavigationBarTitle = Localization.tr("Localizable", "action_buttons_buy_navigation_bar_title")
  /// Can’t find your token? Go to the Market section on the main page and add it to your portfolio for selling.
  public static let actionButtonsSellEmptySearchMessage = Localization.tr("Localizable", "action_buttons_sell_empty_search_message")
  /// Sell
  public static let actionButtonsSellNavigationBarTitle = Localization.tr("Localizable", "action_buttons_sell_navigation_bar_title")
  /// The action is currently unavailable. Please try again later or refresh the data by swiping down on the screen.
  public static let actionButtonsSomethingWrongAlertMessage = Localization.tr("Localizable", "action_buttons_something_wrong_alert_message")
  /// Action is unavailable
  public static let actionButtonsSomethingWrongAlertTitle = Localization.tr("Localizable", "action_buttons_something_wrong_alert_title")
  /// Choose the Token
  public static let actionButtonsSwapChooseToken = Localization.tr("Localizable", "action_buttons_swap_choose_token")
  /// Can’t find your token? Go to the Market section on the main page and add it to your portfolio for swapping.
  public static let actionButtonsSwapEmptySearchMessage = Localization.tr("Localizable", "action_buttons_swap_empty_search_message")
  /// Swap
  public static let actionButtonsSwapNavigationBarTitle = Localization.tr("Localizable", "action_buttons_swap_navigation_bar_title")
  /// There are no available tokens to swap with the selected token. Please choose another one.
  public static let actionButtonsSwapNoAvailablePairNotificationMessage = Localization.tr("Localizable", "action_buttons_swap_no_available_pair_notification_message")
  /// No available pair
  public static let actionButtonsSwapNoAvailablePairNotificationTitle = Localization.tr("Localizable", "action_buttons_swap_no_available_pair_notification_title")
  /// To use the exchange feature, your portfolio must contain at least 2 tokens.
  public static let actionButtonsSwapNoTokensAddedAlertMessage = Localization.tr("Localizable", "action_buttons_swap_no_tokens_added_alert_message")
  /// Add tokens
  public static let actionButtonsSwapNoTokensAddedAlertTitle = Localization.tr("Localizable", "action_buttons_swap_no_tokens_added_alert_title")
  /// You only have 1 token added to your portfolio. To use the exchange feature, you need to add at least 2 tokens.
  public static let actionButtonsSwapNotEnoughTokensAlertMessage = Localization.tr("Localizable", "action_buttons_swap_not_enough_tokens_alert_message")
  /// Add tokens
  public static let actionButtonsSwapNotEnoughTokensAlertTitle = Localization.tr("Localizable", "action_buttons_swap_not_enough_tokens_alert_title")
  /// Choose the token you want to receive
  public static let actionButtonsYouWantToReceive = Localization.tr("Localizable", "action_buttons_you_want_to_receive")
  /// Choose the token you want to swap
  public static let actionButtonsYouWantToSwap = Localization.tr("Localizable", "action_buttons_you_want_to_swap")
  /// Choose network
  public static let addCustomTokenChooseNetwork = Localization.tr("Localizable", "add_custom_token_choose_network")
  /// Add custom token
  public static let addCustomTokenTitle = Localization.tr("Localizable", "add_custom_token_title")
  /// Manage tokens
  public static let addTokensTitle = Localization.tr("Localizable", "add_tokens_title")
  /// Send only %1$@ (%2$@) from %3$@ network to this address. Using other tokens and networks may result in loss of funds.
  public static func addressQrCodeMessageFormat(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return Localization.tr("Localizable", "address_qr_code_message_format", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// Default
  public static let addressTypeDefault = Localization.tr("Localizable", "address_type_default")
  /// Legacy
  public static let addressTypeLegacy = Localization.tr("Localizable", "address_type_legacy")
  /// Thank you for your feedback
  public static let alertAppFeedbackSentMessage = Localization.tr("Localizable", "alert_app_feedback_sent_message")
  /// Sent successfully
  public static let alertAppFeedbackSentTitle = Localization.tr("Localizable", "alert_app_feedback_sent_title")
  /// How to scan
  public static let alertButtonHowToScan = Localization.tr("Localizable", "alert_button_how_to_scan")
  /// Request support
  public static let alertButtonRequestSupport = Localization.tr("Localizable", "alert_button_request_support")
  /// Try again
  public static let alertButtonTryAgain = Localization.tr("Localizable", "alert_button_try_again")
  /// This feature is disabled in Demo mode
  public static let alertDemoFeatureDisabled = Localization.tr("Localizable", "alert_demo_feature_disabled")
  /// Failed to send the email
  public static let alertFailedToSendEmailTitle = Localization.tr("Localizable", "alert_failed_to_send_email_title")
  /// Reason: %@
  public static func alertFailedToSendTransactionMessage(_ p1: Any) -> String {
    return Localization.tr("Localizable", "alert_failed_to_send_transaction_message", String(describing: p1))
  }
  /// The selected does not support the %1$@ network
  public static func alertManageTokensUnsupportedBlockchainByCardMessage(_ p1: Any) -> String {
    return Localization.tr("Localizable", "alert_manage_tokens_unsupported_blockchain_by_card_message", String(describing: p1))
  }
  /// To activate the %1$@ blockchain's cryptographic encryption, you'll need to reset the wallet to factory settings. Please withdraw your funds before doing so to ensure that you don't lose them, and then complete the reset process. Access to the current wallet will not be possible after the reset.
  public static func alertManageTokensUnsupportedCurveMessage(_ p1: Any) -> String {
    return Localization.tr("Localizable", "alert_manage_tokens_unsupported_curve_message", String(describing: p1))
  }
  /// Tokens in %1$@ network are not supported by this card or ring due to firmware limitation.
  public static func alertManageTokensUnsupportedMessage(_ p1: Any) -> String {
    return Localization.tr("Localizable", "alert_manage_tokens_unsupported_message", String(describing: p1))
  }
  /// Thank you for your feedback. We will respond as soon as possible
  public static let alertNegativeAppRateSentMessage = Localization.tr("Localizable", "alert_negative_app_rate_sent_message")
  /// Your suggestions were sent
  public static let alertNegativeAppRateSentTitle = Localization.tr("Localizable", "alert_negative_app_rate_sent_title")
  /// Please try to tap the card or ring exactly as shown in the animation or read our simple guide, or request support. If the problem persists, please request support.
  public static let alertTroubleshootingScanCardMessage = Localization.tr("Localizable", "alert_troubleshooting_scan_card_message")
  /// Are you having difficulty scanning your card or ring?
  public static let alertTroubleshootingScanCardTitle = Localization.tr("Localizable", "alert_troubleshooting_scan_card_title")
  /// Set an access code to enable biometrics
  public static let appSettingsAccessCodeWarning = Localization.tr("Localizable", "app_settings_access_code_warning")
  /// Use %1$@ to unlock your wallet and approve sensitive actions, like signing transactions. For hardware wallets, a card or ring is still required to sign.
  public static func appSettingsBiometricsFooter(_ p1: Any) -> String {
    return Localization.tr("Localizable", "app_settings_biometrics_footer", String(describing: p1))
  }
  /// Default Fee
  public static let appSettingsDefaultFee = Localization.tr("Localizable", "app_settings_default_fee")
  /// Enable Default Fee to set transaction fees automatically and skip the Fee page when sending funds. You can always go back to this page if necessary.
  public static let appSettingsDefaultFeeFooter = Localization.tr("Localizable", "app_settings_default_fee_footer")
  /// Disabling %1$@ will require you to enter your passcode to unlock the app and to interact with your wallet.
  public static func appSettingsOffBiometricsAlertMessage(_ p1: Any) -> String {
    return Localization.tr("Localizable", "app_settings_off_biometrics_alert_message", String(describing: p1))
  }
  /// You'll be asked for your access code later for secure storage.
  public static let appSettingsOffRequireAccessCodeAlertMessage = Localization.tr("Localizable", "app_settings_off_require_access_code_alert_message")
  /// This will delete all saved wallet access codes. You'll need to enter the access code again to use the wallet.
  public static let appSettingsOffSavedAccessCodeAlertMessage = Localization.tr("Localizable", "app_settings_off_saved_access_code_alert_message")
  /// Removing the saved devices deletes all the saved wallets and their access codes from the app.
  public static let appSettingsOffSavedWalletAlertMessage = Localization.tr("Localizable", "app_settings_off_saved_wallet_alert_message")
  /// This will delete all saved wallet access codes. You’ll need to enter the access code again to use the wallet.
  public static let appSettingsOnRequireAccessCodeAlertMessage = Localization.tr("Localizable", "app_settings_on_require_access_code_alert_message")
  /// Require Access Code
  public static let appSettingsRequireAccessCode = Localization.tr("Localizable", "app_settings_require_access_code")
  /// This option turns off biometrics for sensitive actions. You’ll need to enter your access code each time you sign a transaction.
  public static let appSettingsRequireAccessCodeFooter = Localization.tr("Localizable", "app_settings_require_access_code_footer")
  /// Save Access Code
  public static let appSettingsSavedAccessCodes = Localization.tr("Localizable", "app_settings_saved_access_codes")
  /// Biometric authentication will be requested instead of the access code for interactions with your card or ring.
  public static let appSettingsSavedAccessCodesFooter = Localization.tr("Localizable", "app_settings_saved_access_codes_footer")
  /// Keep the wallet in the app
  public static let appSettingsSavedWallet = Localization.tr("Localizable", "app_settings_saved_wallet")
  /// Enable to link all the wallets to Tangem app. Biometric authentication will be required for unlocking the app. Transaction signing requires tapping your Tangem card or ring.
  public static let appSettingsSavedWalletFooter = Localization.tr("Localizable", "app_settings_saved_wallet_footer")
  /// Dark
  public static let appSettingsThemeModeDark = Localization.tr("Localizable", "app_settings_theme_mode_dark")
  /// Light
  public static let appSettingsThemeModeLight = Localization.tr("Localizable", "app_settings_theme_mode_light")
  /// System default
  public static let appSettingsThemeModeSystem = Localization.tr("Localizable", "app_settings_theme_mode_system")
  /// If system is selected, the app will auto-adjust based on your device's system settings
  public static let appSettingsThemeSelectionFooter = Localization.tr("Localizable", "app_settings_theme_selection_footer")
  /// System
  public static let appSettingsThemeSelectionSystemShort = Localization.tr("Localizable", "app_settings_theme_selection_system_short")
  /// Theme
  public static let appSettingsThemeSelectorTitle = Localization.tr("Localizable", "app_settings_theme_selector_title")
  /// App settings
  public static let appSettingsTitle = Localization.tr("Localizable", "app_settings_title")
  /// Go to settings to enable biometric authentication in the Tangem app
  public static let appSettingsWarningSubtitle = Localization.tr("Localizable", "app_settings_warning_subtitle")
  /// Enable biometric authentication
  public static let appSettingsWarningTitle = Localization.tr("Localizable", "app_settings_warning_title")
  /// Add wallet
  public static let authInfoAddWalletTitle = Localization.tr("Localizable", "auth_info_add_wallet_title")
  /// Select a wallet to log in
  public static let authInfoSubtitle = Localization.tr("Localizable", "auth_info_subtitle")
  /// Welcome back!
  public static let authInfoTitle = Localization.tr("Localizable", "auth_info_title")
  /// Plural format key: "%#@format@"
  public static func authWalletHardwareDescription(_ p1: Int) -> String {
    return Localization.tr("Localizable", "auth_wallet_hardware_description", p1)
  }
  /// Mobile Wallet
  public static let authWalletMobileDescription = Localization.tr("Localizable", "auth_wallet_mobile_description")
  /// You successfully backed up your wallet.
  public static let backupCompleteDescription = Localization.tr("Localizable", "backup_complete_description")
  /// These words cannot be recovered if lost. Store them securely.
  public static let backupCompleteSeedDescription = Localization.tr("Localizable", "backup_complete_seed_description")
  /// Backup completed
  public static let backupCompleteTitle = Localization.tr("Localizable", "backup_complete_title")
  /// Your secret recovery phrase is a set of %@ random words for accessing and recovering your wallet.
  public static func backupInfoDescription(_ p1: Any) -> String {
    return Localization.tr("Localizable", "backup_info_description", String(describing: p1))
  }
  /// If you lose this phrase, it cannot be recovered. Keep it completely secure.
  public static let backupInfoKeepDescription = Localization.tr("Localizable", "backup_info_keep_description")
  /// Keep it safe
  public static let backupInfoKeepTitle = Localization.tr("Localizable", "backup_info_keep_title")
  /// Save these %@ words in a secure place that only you can access, and never share them with anyone.
  public static func backupInfoSaveDescription(_ p1: Any) -> String {
    return Localization.tr("Localizable", "backup_info_save_description", String(describing: p1))
  }
  /// No recovery possible
  public static let backupInfoSaveTitle = Localization.tr("Localizable", "backup_info_save_title")
  /// Recovery phrase
  public static let backupInfoTitle = Localization.tr("Localizable", "backup_info_title")
  /// The %@ words below are your wallet's recovery phrase. Never share these words with anyone. Tangem will never ask you for them. Use them to restore your wallet if you lose your device.
  public static func backupSeedCaution(_ p1: Any) -> String {
    return Localization.tr("Localizable", "backup_seed_caution", String(describing: p1))
  }
  /// Write down these %@ words in numerical order and keep them safe and private
  public static func backupSeedDescription(_ p1: Any) -> String {
    return Localization.tr("Localizable", "backup_seed_description", String(describing: p1))
  }
  /// You are fully responsible for securing your wallet and safely backing up your recovery phrase.
  public static let backupSeedResponsibility = Localization.tr("Localizable", "backup_seed_responsibility")
  /// Recovery phrase
  public static let backupSeedTitle = Localization.tr("Localizable", "backup_seed_title")
  /// To hide or show your balances, simply flip your device screen down, or switch it off in Settings
  public static let balanceHiddenDescription = Localization.tr("Localizable", "balance_hidden_description")
  /// Don't show again
  public static let balanceHiddenDoNotShowButton = Localization.tr("Localizable", "balance_hidden_do_not_show_button")
  /// Got it
  public static let balanceHiddenGotItButton = Localization.tr("Localizable", "balance_hidden_got_it_button")
  /// Balances are hidden
  public static let balanceHiddenTitle = Localization.tr("Localizable", "balance_hidden_title")
  /// According to the blockchain developers, Kaspa tokens are currently in beta. Stay tuned for updates!
  public static let betaModeWarningMessage = Localization.tr("Localizable", "beta_mode_warning_message")
  /// Beta Mode
  public static let betaModeWarningTitle = Localization.tr("Localizable", "beta_mode_warning_title")
  /// Touch ID is used to save your cards and rings in the app
  public static let biometryTouchIdReason = Localization.tr("Localizable", "biometry_touch_id_reason")
  /// An error occurred while processing your promo code. Please try again later.
  public static let bitcoinPromoActivationError = Localization.tr("Localizable", "bitcoin_promo_activation_error")
  /// Activation error
  public static let bitcoinPromoActivationErrorTitle = Localization.tr("Localizable", "bitcoin_promo_activation_error_title")
  /// Your promo code was successfully activated. The reward will be credited to your Bitcoin account within 14 days.
  public static let bitcoinPromoActivationSuccess = Localization.tr("Localizable", "bitcoin_promo_activation_success")
  /// Promo Code Activated
  public static let bitcoinPromoActivationSuccessTitle = Localization.tr("Localizable", "bitcoin_promo_activation_success_title")
  /// This promo code has already been used and cannot be activated again.
  public static let bitcoinPromoAlreadyActivated = Localization.tr("Localizable", "bitcoin_promo_already_activated")
  /// Code unavailable
  public static let bitcoinPromoAlreadyActivatedTitle = Localization.tr("Localizable", "bitcoin_promo_already_activated_title")
  /// This promo code is not valid and cannot be activated.
  public static let bitcoinPromoInvalidCode = Localization.tr("Localizable", "bitcoin_promo_invalid_code")
  /// Invalid code
  public static let bitcoinPromoInvalidCodeTitle = Localization.tr("Localizable", "bitcoin_promo_invalid_code_title")
  /// A Bitcoin address is required to receive the bonus. Please add one to your wallet and retry the activation.
  public static let bitcoinPromoNoAddress = Localization.tr("Localizable", "bitcoin_promo_no_address")
  /// Bitcoin address required
  public static let bitcoinPromoNoAddressTitle = Localization.tr("Localizable", "bitcoin_promo_no_address_title")
  /// Start backup process
  public static let buttonStartBackupProcess = Localization.tr("Localizable", "button_start_backup_process")
  /// Use a bank card or other payment methods
  public static let buyTokenDescription = Localization.tr("Localizable", "buy_token_description")
  /// Plural format key: "%#@format@"
  public static func cardLabelCardCount(_ p1: Int) -> String {
    return Localization.tr("Localizable", "card_label_card_count", p1)
  }
  /// Plural format key: "%#@format@"
  public static func cardLabelTokenCount(_ p1: Int) -> String {
    return Localization.tr("Localizable", "card_label_token_count", p1)
  }
  /// Please reset the next device to continue.
  public static let cardResetAlertContinueMessage = Localization.tr("Localizable", "card_reset_alert_continue_message")
  /// Wallet reset
  public static let cardResetAlertContinueTitle = Localization.tr("Localizable", "card_reset_alert_continue_title")
  /// All Tangem devices have been reset. You can now continue upgrading your wallet.
  public static let cardResetAlertFinishMessage = Localization.tr("Localizable", "card_reset_alert_finish_message")
  /// Upgrade again
  public static let cardResetAlertFinishOkButton = Localization.tr("Localizable", "card_reset_alert_finish_ok_button")
  /// Reset complete
  public static let cardResetAlertFinishTitle = Localization.tr("Localizable", "card_reset_alert_finish_title")
  /// We recommend completing the reset process for all Tangem devices in this wallet.
  public static let cardResetAlertIncompleteMessage = Localization.tr("Localizable", "card_reset_alert_incomplete_message")
  /// Some Tangem devices still need to be reset.
  public static let cardResetAlertIncompleteTitle = Localization.tr("Localizable", "card_reset_alert_incomplete_title")
  /// Disable this option if you don't want this card to be used to reset access codes on other cards or rings in this wallet. Please note that this will also prevent you from resetting the access code on this card.
  public static let cardSettingsAccessCodeRecoveryDisabledDescription = Localization.tr("Localizable", "card_settings_access_code_recovery_disabled_description")
  /// Allows you to use this card to reset access code on other cards in this wallet
  public static let cardSettingsAccessCodeRecoveryEnabledDescription = Localization.tr("Localizable", "card_settings_access_code_recovery_enabled_description")
  /// Disable the ability to reset the access code on this card or other cards in this wallet
  public static let cardSettingsAccessCodeRecoveryFooter = Localization.tr("Localizable", "card_settings_access_code_recovery_footer")
  /// Access code recovery
  public static let cardSettingsAccessCodeRecoveryTitle = Localization.tr("Localizable", "card_settings_access_code_recovery_title")
  /// Reset
  public static let cardSettingsActionSheetReset = Localization.tr("Localizable", "card_settings_action_sheet_reset")
  /// Are you sure you want to do this?
  public static let cardSettingsActionSheetTitle = Localization.tr("Localizable", "card_settings_action_sheet_title")
  /// Change Access Code
  public static let cardSettingsChangeAccessCode = Localization.tr("Localizable", "card_settings_change_access_code")
  /// Access code will be changed on this card or ring only
  public static let cardSettingsChangeAccessCodeFooter = Localization.tr("Localizable", "card_settings_change_access_code_footer")
  /// All Tangem devices in the selected wallet have been reset to factory settings. You can now create a new wallet.
  public static let cardSettingsCompletedResetAlertMessage = Localization.tr("Localizable", "card_settings_completed_reset_alert_message")
  /// Reset complete
  public static let cardSettingsCompletedResetAlertTitle = Localization.tr("Localizable", "card_settings_completed_reset_alert_title")
  /// Do you want to reset the next device in this wallet?
  public static let cardSettingsContinueResetAlertMessage = Localization.tr("Localizable", "card_settings_continue_reset_alert_message")
  /// Wallet reset
  public static let cardSettingsContinueResetAlertTitle = Localization.tr("Localizable", "card_settings_continue_reset_alert_title")
  /// We recommend completing the reset process for all Tangem devices in this wallet
  public static let cardSettingsInterruptedResetAlertMessage = Localization.tr("Localizable", "card_settings_interrupted_reset_alert_message")
  /// You haven't reset all your Tangem devices
  public static let cardSettingsInterruptedResetAlertTitle = Localization.tr("Localizable", "card_settings_interrupted_reset_alert_title")
  /// Reset to Factory Settings
  public static let cardSettingsResetCardToFactory = Localization.tr("Localizable", "card_settings_reset_card_to_factory")
  /// Security Mode
  public static let cardSettingsSecurityMode = Localization.tr("Localizable", "card_settings_security_mode")
  /// Device settings
  public static let cardSettingsTitle = Localization.tr("Localizable", "card_settings_title")
  /// In addition to network fee, the Cardano network charges %1$@ ADA when transacting with the %2$@ token
  public static func cardanoCoinWillBeSendWithTokenDescription(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "cardano_coin_will_be_send_with_token_description", String(describing: p1), String(describing: p2))
  }
  /// Cardano transaction requirements
  public static let cardanoCoinWillBeSendWithTokenTitle = Localization.tr("Localizable", "cardano_coin_will_be_send_with_token_title")
  /// To make a %1$@ transaction, you must deposit some ADA to cover the network fee and minimum ADA value (5 ADA recommended)
  public static func cardanoInsufficientBalanceToSendTokenDescription(_ p1: Any) -> String {
    return Localization.tr("Localizable", "cardano_insufficient_balance_to_send_token_description", String(describing: p1))
  }
  /// Insufficient ADA for token transfer
  public static let cardanoInsufficientBalanceToSendTokenTitle = Localization.tr("Localizable", "cardano_insufficient_balance_to_send_token_title")
  /// You must maintain some ADA because you have some tokens on the Cardano blockchain
  public static let cardanoMaxAmountHasTokenDescription = Localization.tr("Localizable", "cardano_max_amount_has_token_description")
  /// Not enough ADA
  public static let cardanoMaxAmountHasTokenTitle = Localization.tr("Localizable", "cardano_max_amount_has_token_title")
  /// Accept
  public static let commonAccept = Localization.tr("Localizable", "common_accept")
  /// Access denied
  public static let commonAccessDenied = Localization.tr("Localizable", "common_access_denied")
  /// Account
  public static let commonAccount = Localization.tr("Localizable", "common_account")
  /// Accounts
  public static let commonAccounts = Localization.tr("Localizable", "common_accounts")
  /// Activate
  public static let commonActivate = Localization.tr("Localizable", "common_activate")
  /// Add
  public static let commonAdd = Localization.tr("Localizable", "common_add")
  /// Add to portfolio
  public static let commonAddToPortfolio = Localization.tr("Localizable", "common_add_to_portfolio")
  /// Add token
  public static let commonAddToken = Localization.tr("Localizable", "common_add_token")
  /// Added
  public static let commonAdded = Localization.tr("Localizable", "common_added")
  /// Address
  public static let commonAddress = Localization.tr("Localizable", "common_address")
  /// All
  public static let commonAll = Localization.tr("Localizable", "common_all")
  /// Allow
  public static let commonAllow = Localization.tr("Localizable", "common_allow")
  /// Amount
  public static let commonAmount = Localization.tr("Localizable", "common_amount")
  /// Analytics
  public static let commonAnalytics = Localization.tr("Localizable", "common_analytics")
  /// and
  public static let commonAnd = Localization.tr("Localizable", "common_and")
  /// Apply
  public static let commonApply = Localization.tr("Localizable", "common_apply")
  /// Approval
  public static let commonApproval = Localization.tr("Localizable", "common_approval")
  /// Approve
  public static let commonApprove = Localization.tr("Localizable", "common_approve")
  /// Attention
  public static let commonAttention = Localization.tr("Localizable", "common_attention")
  /// Available networks
  public static let commonAvailableNetworks = Localization.tr("Localizable", "common_available_networks")
  /// Back
  public static let commonBack = Localization.tr("Localizable", "common_back")
  /// Backup
  public static let commonBackup = Localization.tr("Localizable", "common_backup")
  /// Balance: %@
  public static func commonBalance(_ p1: Any) -> String {
    return Localization.tr("Localizable", "common_balance", String(describing: p1))
  }
  /// Balance
  public static let commonBalanceTitle = Localization.tr("Localizable", "common_balance_title")
  /// Failed to build transaction
  public static let commonBuildTxError = Localization.tr("Localizable", "common_build_tx_error")
  /// Buy
  public static let commonBuy = Localization.tr("Localizable", "common_buy")
  /// Go to %1$@
  public static func commonBuyCurrency(_ p1: Any) -> String {
    return Localization.tr("Localizable", "common_buy_currency", String(describing: p1))
  }
  /// Settings
  public static let commonCameraAlertButtonSettings = Localization.tr("Localizable", "common_camera_alert_button_settings")
  /// You have not given access to your camera, please adjust your privacy settings
  public static let commonCameraDeniedAlertMessage = Localization.tr("Localizable", "common_camera_denied_alert_message")
  /// Camera access denied
  public static let commonCameraDeniedAlertTitle = Localization.tr("Localizable", "common_camera_denied_alert_title")
  /// Cancel
  public static let commonCancel = Localization.tr("Localizable", "common_cancel")
  /// Change
  public static let commonChange = Localization.tr("Localizable", "common_change")
  /// Choose account
  public static let commonChooseAccount = Localization.tr("Localizable", "common_choose_account")
  /// Choose action
  public static let commonChooseAction = Localization.tr("Localizable", "common_choose_action")
  /// Choose network
  public static let commonChooseNetwork = Localization.tr("Localizable", "common_choose_network")
  /// Choose token
  public static let commonChooseToken = Localization.tr("Localizable", "common_choose_token")
  /// Choose wallet
  public static let commonChooseWallet = Localization.tr("Localizable", "common_choose_wallet")
  /// Claim
  public static let commonClaim = Localization.tr("Localizable", "common_claim")
  /// Claim rewards
  public static let commonClaimRewards = Localization.tr("Localizable", "common_claim_rewards")
  /// Close
  public static let commonClose = Localization.tr("Localizable", "common_close")
  /// Coming soon
  public static let commonComingSoon = Localization.tr("Localizable", "common_coming_soon")
  /// Confirm
  public static let commonConfirm = Localization.tr("Localizable", "common_confirm")
  /// Connecting
  public static let commonConnecting = Localization.tr("Localizable", "common_connecting")
  /// Contact support
  public static let commonContactSupport = Localization.tr("Localizable", "common_contact_support")
  /// Contact Tangem Support
  public static let commonContactTangemSupport = Localization.tr("Localizable", "common_contact_tangem_support")
  /// Contact Visa Support
  public static let commonContactVisaSupport = Localization.tr("Localizable", "common_contact_visa_support")
  /// Continue
  public static let commonContinue = Localization.tr("Localizable", "common_continue")
  /// Convert
  public static let commonConvert = Localization.tr("Localizable", "common_convert")
  /// Copy
  public static let commonCopy = Localization.tr("Localizable", "common_copy")
  /// Copy address
  public static let commonCopyAddress = Localization.tr("Localizable", "common_copy_address")
  /// Create
  public static let commonCreate = Localization.tr("Localizable", "common_create")
  /// %1$@ (%2$@)
  public static func commonCryptoFiatFormat(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "common_crypto_fiat_format", String(describing: p1), String(describing: p2))
  }
  /// Custom
  public static let commonCustom = Localization.tr("Localizable", "common_custom")
  /// Plural format key: "%#@format@"
  public static func commonDaysNoParam(_ p1: Int) -> String {
    return Localization.tr("Localizable", "common_days_no_param", p1)
  }
  /// Delete
  public static let commonDelete = Localization.tr("Localizable", "common_delete")
  /// Disable
  public static let commonDisable = Localization.tr("Localizable", "common_disable")
  /// Disabled
  public static let commonDisabled = Localization.tr("Localizable", "common_disabled")
  /// Disconnect
  public static let commonDisconnect = Localization.tr("Localizable", "common_disconnect")
  /// Done
  public static let commonDone = Localization.tr("Localizable", "common_done")
  /// Edit
  public static let commonEdit = Localization.tr("Localizable", "common_edit")
  /// Enable
  public static let commonEnable = Localization.tr("Localizable", "common_enable")
  /// Enabled
  public static let commonEnabled = Localization.tr("Localizable", "common_enabled")
  /// Error
  public static let commonError = Localization.tr("Localizable", "common_error")
  /// Top-up network fee
  public static let commonEstimatedFee = Localization.tr("Localizable", "common_estimated_fee")
  /// Swap
  public static let commonExchange = Localization.tr("Localizable", "common_exchange")
  /// Explore
  public static let commonExplore = Localization.tr("Localizable", "common_explore")
  /// Explore transaction history
  public static let commonExploreTransactionHistory = Localization.tr("Localizable", "common_explore_transaction_history")
  /// Explorer
  public static let commonExplorer = Localization.tr("Localizable", "common_explorer")
  /// Failed to get fee
  public static let commonFeeError = Localization.tr("Localizable", "common_fee_error")
  /// Network fees are charges users pay to process and confirm transactions. The fee amount can be affected by network congestion, transaction size, and execution priority. %@
  public static func commonFeeSelectorFooter(_ p1: Any) -> String {
    return Localization.tr("Localizable", "common_fee_selector_footer", String(describing: p1))
  }
  /// Fast
  public static let commonFeeSelectorOptionFast = Localization.tr("Localizable", "common_fee_selector_option_fast")
  /// Market
  public static let commonFeeSelectorOptionMarket = Localization.tr("Localizable", "common_fee_selector_option_market")
  /// Slow
  public static let commonFeeSelectorOptionSlow = Localization.tr("Localizable", "common_fee_selector_option_slow")
  /// Speed and fee
  public static let commonFeeSelectorTitle = Localization.tr("Localizable", "common_fee_selector_title")
  /// Finish
  public static let commonFinish = Localization.tr("Localizable", "common_finish")
  /// Forget
  public static let commonForget = Localization.tr("Localizable", "common_forget")
  /// Free
  public static let commonFree = Localization.tr("Localizable", "common_free")
  /// From
  public static let commonFrom = Localization.tr("Localizable", "common_from")
  /// From %@
  public static func commonFromWalletName(_ p1: Any) -> String {
    return Localization.tr("Localizable", "common_from_wallet_name", String(describing: p1))
  }
  /// Synchronize addresses
  public static let commonGenerateAddresses = Localization.tr("Localizable", "common_generate_addresses")
  /// Get started
  public static let commonGetStarted = Localization.tr("Localizable", "common_get_started")
  /// Get token
  public static let commonGetToken = Localization.tr("Localizable", "common_get_token")
  /// Go to provider
  public static let commonGoToProvider = Localization.tr("Localizable", "common_go_to_provider")
  /// Go to token
  public static let commonGoToToken = Localization.tr("Localizable", "common_go_to_token")
  /// Got it
  public static let commonGotIt = Localization.tr("Localizable", "common_got_it")
  /// Hide
  public static let commonHide = Localization.tr("Localizable", "common_hide")
  /// Hold to %@
  public static func commonHoldTo(_ p1: Any) -> String {
    return Localization.tr("Localizable", "common_hold_to", String(describing: p1))
  }
  /// hour
  public static let commonHour = Localization.tr("Localizable", "common_hour")
  /// Import
  public static let commonImport = Localization.tr("Localizable", "common_import")
  /// In progress
  public static let commonInProgress = Localization.tr("Localizable", "common_in_progress")
  /// Later
  public static let commonLater = Localization.tr("Localizable", "common_later")
  /// Learn & Earn
  public static let commonLearnAndEarn = Localization.tr("Localizable", "common_learn_and_earn")
  /// Learn more
  public static let commonLearnMore = Localization.tr("Localizable", "common_learn_more")
  /// %1$@ left
  public static func commonLeft(_ p1: Any) -> String {
    return Localization.tr("Localizable", "common_left", String(describing: p1))
  }
  /// Legacy Bitcoin
  public static let commonLegacyBitcoinAddress = Localization.tr("Localizable", "common_legacy_bitcoin_address")
  /// Locked
  public static let commonLocked = Localization.tr("Localizable", "common_locked")
  /// Locked Wallets
  public static let commonLockedWallets = Localization.tr("Localizable", "common_locked_wallets")
  /// Main network
  public static let commonMainNetwork = Localization.tr("Localizable", "common_main_network")
  /// month
  public static let commonMonth = Localization.tr("Localizable", "common_month")
  /// Network fee
  public static let commonNetworkFeeTitle = Localization.tr("Localizable", "common_network_fee_title")
  /// Amount sent will be reduced by %1$@ (%2$@) to cover the selected fee level
  public static func commonNetworkFeeWarningContent(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "common_network_fee_warning_content", String(describing: p1), String(describing: p2))
  }
  /// Plural format key: "%#@format@"
  public static func commonNetworksCount(_ p1: Int) -> String {
    return Localization.tr("Localizable", "common_networks_count", p1)
  }
  /// New address
  public static let commonNewAddress = Localization.tr("Localizable", "common_new_address")
  /// News
  public static let commonNews = Localization.tr("Localizable", "common_news")
  /// Next
  public static let commonNext = Localization.tr("Localizable", "common_next")
  /// NFT
  public static let commonNft = Localization.tr("Localizable", "common_nft")
  /// No
  public static let commonNo = Localization.tr("Localizable", "common_no")
  /// No address
  public static let commonNoAddress = Localization.tr("Localizable", "common_no_address")
  /// Not Added
  public static let commonNotAdded = Localization.tr("Localizable", "common_not_added")
  /// Not available
  public static let commonNotAvailable = Localization.tr("Localizable", "common_not_available")
  /// Not now
  public static let commonNotNow = Localization.tr("Localizable", "common_not_now")
  /// Now
  public static let commonNow = Localization.tr("Localizable", "common_now")
  /// OK
  public static let commonOk = Localization.tr("Localizable", "common_ok")
  /// Open in Browser
  public static let commonOpenInBrowser = Localization.tr("Localizable", "common_open_in_browser")
  /// or
  public static let commonOr = Localization.tr("Localizable", "common_or")
  /// Primary card
  public static let commonOriginCard = Localization.tr("Localizable", "common_origin_card")
  /// Primary ring
  public static let commonOriginRing = Localization.tr("Localizable", "common_origin_ring")
  /// Passphrase
  public static let commonPassphrase = Localization.tr("Localizable", "common_passphrase")
  /// Paste
  public static let commonPaste = Localization.tr("Localizable", "common_paste")
  /// Privacy Policy
  public static let commonPrivacyPolicy = Localization.tr("Localizable", "common_privacy_policy")
  /// %1$@-%2$@
  public static func commonRange(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "common_range", String(describing: p1), String(describing: p2))
  }
  /// %1$@ — %2$@
  public static func commonRangeWithSpace(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "common_range_with_space", String(describing: p1), String(describing: p2))
  }
  /// Read more
  public static let commonReadMore = Localization.tr("Localizable", "common_read_more")
  /// Receive
  public static let commonReceive = Localization.tr("Localizable", "common_receive")
  /// Recommended
  public static let commonRecommended = Localization.tr("Localizable", "common_recommended")
  /// Reject
  public static let commonReject = Localization.tr("Localizable", "common_reject")
  /// Reload
  public static let commonReload = Localization.tr("Localizable", "common_reload")
  /// Rename
  public static let commonRename = Localization.tr("Localizable", "common_rename")
  /// Required
  public static let commonRequired = Localization.tr("Localizable", "common_required")
  /// Reset
  public static let commonReset = Localization.tr("Localizable", "common_reset")
  /// Retry
  public static let commonRetry = Localization.tr("Localizable", "common_retry")
  /// Save
  public static let commonSave = Localization.tr("Localizable", "common_save")
  /// Save changes
  public static let commonSaveChanges = Localization.tr("Localizable", "common_save_changes")
  /// Search
  public static let commonSearch = Localization.tr("Localizable", "common_search")
  /// Search tokens
  public static let commonSearchTokens = Localization.tr("Localizable", "common_search_tokens")
  /// sec
  public static let commonSecondNoParam = Localization.tr("Localizable", "common_second_no_param")
  /// See all
  public static let commonSeeAll = Localization.tr("Localizable", "common_see_all")
  /// Seed phrase
  public static let commonSeedPhrase = Localization.tr("Localizable", "common_seed_phrase")
  /// Select action
  public static let commonSelectAction = Localization.tr("Localizable", "common_select_action")
  /// Sell
  public static let commonSell = Localization.tr("Localizable", "common_sell")
  /// Send
  public static let commonSend = Localization.tr("Localizable", "common_send")
  /// Failed to send transaction
  public static let commonSendTxError = Localization.tr("Localizable", "common_send_tx_error")
  /// The server is not available, please try again later
  public static let commonServerUnavailable = Localization.tr("Localizable", "common_server_unavailable")
  /// Share
  public static let commonShare = Localization.tr("Localizable", "common_share")
  /// Share Link
  public static let commonShareLink = Localization.tr("Localizable", "common_share_link")
  /// Show less
  public static let commonShowLess = Localization.tr("Localizable", "common_show_less")
  /// Show more
  public static let commonShowMore = Localization.tr("Localizable", "common_show_more")
  /// Sign
  public static let commonSign = Localization.tr("Localizable", "common_sign")
  /// Sign and send
  public static let commonSignAndSend = Localization.tr("Localizable", "common_sign_and_send")
  /// Skip
  public static let commonSkip = Localization.tr("Localizable", "common_skip")
  /// Something went wrong
  public static let commonSomethingWentWrong = Localization.tr("Localizable", "common_something_went_wrong")
  /// Stake
  public static let commonStake = Localization.tr("Localizable", "common_stake")
  /// Staking
  public static let commonStaking = Localization.tr("Localizable", "common_staking")
  /// Start
  public static let commonStart = Localization.tr("Localizable", "common_start")
  /// Submit
  public static let commonSubmit = Localization.tr("Localizable", "common_submit")
  /// Success
  public static let commonSuccess = Localization.tr("Localizable", "common_success")
  /// Support
  public static let commonSupport = Localization.tr("Localizable", "common_support")
  /// Supported networks
  public static let commonSupportedNetworks = Localization.tr("Localizable", "common_supported_networks")
  /// Swap
  public static let commonSwap = Localization.tr("Localizable", "common_swap")
  /// Tangem
  public static let commonTangem = Localization.tr("Localizable", "common_tangem")
  /// Tangem Wallet
  public static let commonTangemWallet = Localization.tr("Localizable", "common_tangem_wallet")
  /// Tap and hold
  public static let commonTapAndHoldHint = Localization.tr("Localizable", "common_tap_and_hold_hint")
  /// terms and conditions
  public static let commonTermsAndConditions = Localization.tr("Localizable", "common_terms_and_conditions")
  /// Terms of Use
  public static let commonTermsOfUse = Localization.tr("Localizable", "common_terms_of_use")
  /// To
  public static let commonTo = Localization.tr("Localizable", "common_to")
  /// To %@
  public static func commonToWalletName(_ p1: Any) -> String {
    return Localization.tr("Localizable", "common_to_wallet_name", String(describing: p1))
  }
  /// Today
  public static let commonToday = Localization.tr("Localizable", "common_today")
  /// Plural format key: "%#@format@"
  public static func commonTokensCount(_ p1: Int) -> String {
    return Localization.tr("Localizable", "common_tokens_count", p1)
  }
  /// Transaction failed
  public static let commonTransactionFailed = Localization.tr("Localizable", "common_transaction_failed")
  /// Transaction status
  public static let commonTransactionStatus = Localization.tr("Localizable", "common_transaction_status")
  /// Transactions
  public static let commonTransactions = Localization.tr("Localizable", "common_transactions")
  /// Transfer
  public static let commonTransfer = Localization.tr("Localizable", "common_transfer")
  /// Unable to load data…
  public static let commonUnableToLoad = Localization.tr("Localizable", "common_unable_to_load")
  /// I understand
  public static let commonUnderstand = Localization.tr("Localizable", "common_understand")
  /// I understand, continue
  public static let commonUnderstandContinue = Localization.tr("Localizable", "common_understand_continue")
  /// There was an error. Please try again.
  public static let commonUnknownError = Localization.tr("Localizable", "common_unknown_error")
  /// Unreachable
  public static let commonUnreachable = Localization.tr("Localizable", "common_unreachable")
  /// Unstake
  public static let commonUnstake = Localization.tr("Localizable", "common_unstake")
  /// Due to %1$@ limitations only %2$li UTXOs can fit in a single transaction. This means you can only send %3$@ or less. You need to reduce the amount.
  public static func commonUtxoValidateWithdrawalMessageWarning(_ p1: Any, _ p2: Int, _ p3: Any) -> String {
    return Localization.tr("Localizable", "common_utxo_validate_withdrawal_message_warning", String(describing: p1), p2, String(describing: p3))
  }
  /// Value copied
  public static let commonValueCopied = Localization.tr("Localizable", "common_value_copied")
  /// Warning
  public static let commonWarning = Localization.tr("Localizable", "common_warning")
  /// week
  public static let commonWeek = Localization.tr("Localizable", "common_week")
  /// with
  public static let commonWith = Localization.tr("Localizable", "common_with")
  /// Yes
  public static let commonYes = Localization.tr("Localizable", "common_yes")
  /// Yield Mode
  public static let commonYieldMode = Localization.tr("Localizable", "common_yield_mode")
  /// Contract address copied!
  public static let contractAddressCopiedMessage = Localization.tr("Localizable", "contract_address_copied_message")
  /// Available networks
  public static let currencySubtitleExpanded = Localization.tr("Localizable", "currency_subtitle_expanded")
  /// Derivation of your token matches the derivation of %1$@. Your token will be added to this account.
  public static func customTokenAnotherAccountDialogDescription(_ p1: Any) -> String {
    return Localization.tr("Localizable", "custom_token_another_account_dialog_description", String(describing: p1))
  }
  /// Derivation belongs to another account.
  public static let customTokenAnotherAccountDialogTitle = Localization.tr("Localizable", "custom_token_another_account_dialog_title")
  /// Token added to %1$@ account
  public static func customTokenAnotherAccountSnackbarText(_ p1: Any) -> String {
    return Localization.tr("Localizable", "custom_token_another_account_snackbar_text", String(describing: p1))
  }
  /// Contract address
  public static let customTokenContractAddressInputTitle = Localization.tr("Localizable", "custom_token_contract_address_input_title")
  /// Please fill in all the fields
  public static let customTokenCreationErrorEmptyFields = Localization.tr("Localizable", "custom_token_creation_error_empty_fields")
  /// Contract address is invalid
  public static let customTokenCreationErrorInvalidContractAddress = Localization.tr("Localizable", "custom_token_creation_error_invalid_contract_address")
  /// Please select the network
  public static let customTokenCreationErrorNetworkNotSelected = Localization.tr("Localizable", "custom_token_creation_error_network_not_selected")
  /// Decimal must be a valid integer, up to %li
  public static func customTokenCreationErrorWrongDecimals(_ p1: Int) -> String {
    return Localization.tr("Localizable", "custom_token_creation_error_wrong_decimals", p1)
  }
  /// Custom derivation
  public static let customTokenCustomDerivation = Localization.tr("Localizable", "custom_token_custom_derivation")
  /// E. g. m/00'/0000'/0'/0/0
  public static let customTokenCustomDerivationPlaceholder = Localization.tr("Localizable", "custom_token_custom_derivation_placeholder")
  /// Enter custom derivation
  public static let customTokenCustomDerivationTitle = Localization.tr("Localizable", "custom_token_custom_derivation_title")
  /// Decimals
  public static let customTokenDecimalsInputTitle = Localization.tr("Localizable", "custom_token_decimals_input_title")
  /// Derivation Path
  public static let customTokenDerivationPath = Localization.tr("Localizable", "custom_token_derivation_path")
  /// Default
  public static let customTokenDerivationPathDefault = Localization.tr("Localizable", "custom_token_derivation_path_default")
  /// E.g. USD Coin
  public static let customTokenNameInputPlaceholder = Localization.tr("Localizable", "custom_token_name_input_placeholder")
  /// Name
  public static let customTokenNameInputTitle = Localization.tr("Localizable", "custom_token_name_input_title")
  /// Network
  public static let customTokenNetworkInputTitle = Localization.tr("Localizable", "custom_token_network_input_title")
  /// Token network
  public static let customTokenNetworkSelectorTitle = Localization.tr("Localizable", "custom_token_network_selector_title")
  /// You can manually add a token that is not natively supported by Tangem
  public static let customTokenSubtitle = Localization.tr("Localizable", "custom_token_subtitle")
  /// E.g. USDC
  public static let customTokenTokenSymbolInputPlaceholder = Localization.tr("Localizable", "custom_token_token_symbol_input_placeholder")
  /// Symbol
  public static let customTokenTokenSymbolInputTitle = Localization.tr("Localizable", "custom_token_token_symbol_input_title")
  /// This token/network has already been added to your list
  public static let customTokenValidationErrorAlreadyAdded = Localization.tr("Localizable", "custom_token_validation_error_already_added")
  /// Note that tokens can be created by [REDACTED_AUTHOR]
  public static let customTokenValidationErrorNotFound = Localization.tr("Localizable", "custom_token_validation_error_not_found")
  /// Be aware of adding scam tokens, they can cost nothing
  public static let customTokenValidationErrorNotFoundDescription = Localization.tr("Localizable", "custom_token_validation_error_not_found_description")
  /// Note that tokens can be created by [REDACTED_AUTHOR]
  public static let customTokenValidationErrorNotFoundTitle = Localization.tr("Localizable", "custom_token_validation_error_not_found_title")
  /// Buy Tangem Wallet
  public static let detailsBuyWallet = Localization.tr("Localizable", "details_buy_wallet")
  /// Chat
  public static let detailsChat = Localization.tr("Localizable", "details_chat")
  /// Access code
  public static let detailsManageSecurityAccessCode = Localization.tr("Localizable", "details_manage_security_access_code")
  /// You will have to submit the correct access code before scanning the card
  public static let detailsManageSecurityAccessCodeDescription = Localization.tr("Localizable", "details_manage_security_access_code_description")
  /// Long Tap
  public static let detailsManageSecurityLongTap = Localization.tr("Localizable", "details_manage_security_long_tap")
  /// This mechanism protects against proximity attacks on a card or ring. It will enforce a delay between reception and execution of a command.
  public static let detailsManageSecurityLongTapDescription = Localization.tr("Localizable", "details_manage_security_long_tap_description")
  /// Long Tap
  public static let detailsManageSecurityLongTapShorter = Localization.tr("Localizable", "details_manage_security_long_tap_shorter")
  /// Passcode
  public static let detailsManageSecurityPasscode = Localization.tr("Localizable", "details_manage_security_passcode")
  /// Before executing any command entailing a change of the card state, you will have to enter the passcode.
  public static let detailsManageSecurityPasscodeDescription = Localization.tr("Localizable", "details_manage_security_passcode_description")
  /// Upgrade to hardware wallet
  public static let detailsMobileWalletUpgradeActionTitle = Localization.tr("Localizable", "details_mobile_wallet_upgrade_action_title")
  /// NFT
  public static let detailsNftTitle = Localization.tr("Localizable", "details_nft_title")
  /// Referral program
  public static let detailsReferralTitle = Localization.tr("Localizable", "details_referral_title")
  /// Flip your device screen down to quickly hide and show balances
  public static let detailsRowDescriptionFlipToHide = Localization.tr("Localizable", "details_row_description_flip_to_hide")
  /// %@ hashes
  public static func detailsRowSubtitleSignedHashesFormat(_ p1: Any) -> String {
    return Localization.tr("Localizable", "details_row_subtitle_signed_hashes_format", String(describing: p1))
  }
  /// Device ID
  public static let detailsRowTitleCid = Localization.tr("Localizable", "details_row_title_cid")
  /// Open support chat
  public static let detailsRowTitleContactToSupportChat = Localization.tr("Localizable", "details_row_title_contact_to_support_chat")
  /// Link More Cards
  public static let detailsRowTitleCreateBackup = Localization.tr("Localizable", "details_row_title_create_backup")
  /// You can add up to three cards or rings to one wallet. It can only be done once.
  public static let detailsRowTitleCreateBackupFooter = Localization.tr("Localizable", "details_row_title_create_backup_footer")
  /// App Currency
  public static let detailsRowTitleCurrency = Localization.tr("Localizable", "details_row_title_currency")
  /// Flip-to-Hide Balances
  public static let detailsRowTitleFlipToHide = Localization.tr("Localizable", "details_row_title_flip_to_hide")
  /// Issuer
  public static let detailsRowTitleIssuer = Localization.tr("Localizable", "details_row_title_issuer")
  /// Signed
  public static let detailsRowTitleSignedHashes = Localization.tr("Localizable", "details_row_title_signed_hashes")
  /// If you forget the code you will lose access to your funds. Code recovery is not possible.
  public static let detailsSecurityManagementWarning = Localization.tr("Localizable", "details_security_management_warning")
  /// Send feedback
  public static let detailsSendFeedback = Localization.tr("Localizable", "details_send_feedback")
  /// Details
  public static let detailsTitle = Localization.tr("Localizable", "details_title")
  /// You can only have one mobile wallet. Upgrade it to Tangem hardware wallet, or add a new hardware wallet.
  public static let detailsWalletsSectionDescription = Localization.tr("Localizable", "details_wallets_section_description")
  /// Terms of service
  public static let disclaimerTitle = Localization.tr("Localizable", "disclaimer_title")
  /// Default Address
  public static let domainReceiveAssetsDefaultAddress = Localization.tr("Localizable", "domain_receive_assets_default_address")
  /// Legacy %@ Address
  public static func domainReceiveAssetsLegacyAddress(_ p1: Any) -> String {
    return Localization.tr("Localizable", "domain_receive_assets_legacy_address", String(describing: p1))
  }
  /// Receive assets
  public static let domainReceiveAssetsNavigationTitle = Localization.tr("Localizable", "domain_receive_assets_navigation_title")
  /// %@ address
  public static func domainReceiveAssetsNetworkNameAddress(_ p1: Any) -> String {
    return Localization.tr("Localizable", "domain_receive_assets_network_name_address", String(describing: p1))
  }
  /// Sending assets in other networks will result in permanent loss.
  public static let domainReceiveAssetsOnboardingDescription = Localization.tr("Localizable", "domain_receive_assets_onboarding_description")
  /// %@ network
  public static func domainReceiveAssetsOnboardingNetworkName(_ p1: Any) -> String {
    return Localization.tr("Localizable", "domain_receive_assets_onboarding_network_name", String(describing: p1))
  }
  /// Send funds using only
  public static let domainReceiveAssetsOnboardingTitle = Localization.tr("Localizable", "domain_receive_assets_onboarding_title")
  /// Best opportunities
  public static let earnBestOpportunities = Localization.tr("Localizable", "earn_best_opportunities")
  /// Clear filter
  public static let earnClearFilter = Localization.tr("Localizable", "earn_clear_filter")
  /// The list is temporarily empty as it’s being refreshed. Check back in a moment.
  public static let earnEmpty = Localization.tr("Localizable", "earn_empty")
  /// All networks
  public static let earnFilterAllNetworks = Localization.tr("Localizable", "earn_filter_all_networks")
  /// All types
  public static let earnFilterAllTypes = Localization.tr("Localizable", "earn_filter_all_types")
  /// Filter by
  public static let earnFilterBy = Localization.tr("Localizable", "earn_filter_by")
  /// My networks
  public static let earnFilterMyNetworks = Localization.tr("Localizable", "earn_filter_my_networks")
  /// Networks
  public static let earnFilterNetworks = Localization.tr("Localizable", "earn_filter_networks")
  /// Mostly used
  public static let earnMostlyUsed = Localization.tr("Localizable", "earn_mostly_used")
  /// No results
  public static let earnNoResults = Localization.tr("Localizable", "earn_no_results")
  /// Earn
  public static let earnTitle = Localization.tr("Localizable", "earn_title")
  /// Hi support team, I've encountered an error with code: %@
  public static func emailPrefaceWcError(_ p1: Any) -> String {
    return Localization.tr("Localizable", "email_preface_wc_error", String(describing: p1))
  }
  /// WalletConnect error
  public static let emailSubjectWcError = Localization.tr("Localizable", "email_subject_wc_error")
  /// You have used a card or ring from another wallet. Tap the card or ring associated with this wallet
  public static let errorWrongWalletTapped = Localization.tr("Localizable", "error_wrong_wallet_tapped")
  /// Not enough funds for the transaction. Please top up your account.
  public static let ethGasRequiredExceedsAllowance = Localization.tr("Localizable", "eth_gas_required_exceeds_allowance")
  /// Swap any asset in your portfolio for this token
  public static let exchangeTokenDescription = Localization.tr("Localizable", "exchange_token_description")
  /// My tokens
  public static let exchangeTokensAvailableTokensHeader = Localization.tr("Localizable", "exchange_tokens_available_tokens_header")
  /// You haven't added any tokens yet. Add tokens via Market to swap
  public static let exchangeTokensEmptyTokens = Localization.tr("Localizable", "exchange_tokens_empty_tokens")
  /// Cannot be swapped for %@
  public static func exchangeTokensUnavailableTokensHeader(_ p1: Any) -> String {
    return Localization.tr("Localizable", "exchange_tokens_unavailable_tokens_header", String(describing: p1))
  }
  /// Provided by %@
  public static func expressByProviderPlaceholder(_ p1: Any) -> String {
    return Localization.tr("Localizable", "express_by_provider_placeholder", String(describing: p1))
  }
  /// Status
  public static let expressCexStatusButtonTitle = Localization.tr("Localizable", "express_cex_status_button_title")
  /// Choose provider
  public static let expressChooseProvider = Localization.tr("Localizable", "express_choose_provider")
  /// Providers facilitate transactions
  public static let expressChooseProvidersSubtitle = Localization.tr("Localizable", "express_choose_providers_subtitle")
  /// Provider
  public static let expressChooseProvidersTitle = Localization.tr("Localizable", "express_choose_providers_title")
  /// Error %1$@. The selected provider cannot process the specified transaction. Please round the value up to %2$@ or change it
  public static func expressErrorProviderAmountRoundup(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "express_error_provider_amount_roundup", String(describing: p1), String(describing: p2))
  }
  /// Selected provider is unavailable at the moment. Please try again later. (Code: %@)
  public static func expressErrorSwapPairUnavailable(_ p1: Any) -> String {
    return Localization.tr("Localizable", "express_error_swap_pair_unavailable", String(describing: p1))
  }
  /// Swaps are unavailable at the moment. Please try again later. (Code: %@)
  public static func expressErrorSwapUnavailable(_ p1: Any) -> String {
    return Localization.tr("Localizable", "express_error_swap_unavailable", String(describing: p1))
  }
  /// Estimated amount
  public static let expressEstimatedAmount = Localization.tr("Localizable", "express_estimated_amount")
  /// Exchange by %@
  public static func expressExchangeBy(_ p1: Any) -> String {
    return Localization.tr("Localizable", "express_exchange_by", String(describing: p1))
  }
  /// Visit provider’s website to refund your money
  public static let expressExchangeNotificationFailedText = Localization.tr("Localizable", "express_exchange_notification_failed_text")
  /// Operation failed by provider
  public static let expressExchangeNotificationFailedTitle = Localization.tr("Localizable", "express_exchange_notification_failed_title")
  /// Your swap is taking longer than usual, but your funds are completely safe and will be delivered. For any questions, you can contact the provider’s support team.
  public static let expressExchangeNotificationLongTransactionTimeText = Localization.tr("Localizable", "express_exchange_notification_long_transaction_time_text")
  /// Long transaction time
  public static let expressExchangeNotificationLongTransactionTimeTitle = Localization.tr("Localizable", "express_exchange_notification_long_transaction_time_title")
  /// The transaction amount was refunded in %1$@ to your wallet due to OKX or bridge rules. %2$@
  public static func expressExchangeNotificationRefundText(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "express_exchange_notification_refund_text", String(describing: p1), String(describing: p2))
  }
  /// The amount was refunded in %1$@ (%2$@ network)
  public static func expressExchangeNotificationRefundTitle(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "express_exchange_notification_refund_title", String(describing: p1), String(describing: p2))
  }
  /// Visit provider’s website for verification
  public static let expressExchangeNotificationVerificationText = Localization.tr("Localizable", "express_exchange_notification_verification_text")
  /// KYC verification required by provider
  public static let expressExchangeNotificationVerificationTitle = Localization.tr("Localizable", "express_exchange_notification_verification_title")
  /// Purchase completed
  public static let expressExchangeStatusBought = Localization.tr("Localizable", "express_exchange_status_bought")
  /// Awaiting Purchase
  public static let expressExchangeStatusBuying = Localization.tr("Localizable", "express_exchange_status_buying")
  /// Awaiting Purchase...
  public static let expressExchangeStatusBuyingActive = Localization.tr("Localizable", "express_exchange_status_buying_active")
  /// Transaction canceled
  public static let expressExchangeStatusCanceled = Localization.tr("Localizable", "express_exchange_status_canceled")
  /// Deposit confirmed
  public static let expressExchangeStatusConfirmed = Localization.tr("Localizable", "express_exchange_status_confirmed")
  /// Waiting for confirmation
  public static let expressExchangeStatusConfirming = Localization.tr("Localizable", "express_exchange_status_confirming")
  /// Waiting for confirmation...
  public static let expressExchangeStatusConfirmingActive = Localization.tr("Localizable", "express_exchange_status_confirming_active")
  /// Exchange completed
  public static let expressExchangeStatusExchanged = Localization.tr("Localizable", "express_exchange_status_exchanged")
  /// Waiting for exchange
  public static let expressExchangeStatusExchanging = Localization.tr("Localizable", "express_exchange_status_exchanging")
  /// Waiting for exchange...
  public static let expressExchangeStatusExchangingActive = Localization.tr("Localizable", "express_exchange_status_exchanging_active")
  /// Exchange failed
  public static let expressExchangeStatusFailed = Localization.tr("Localizable", "express_exchange_status_failed")
  /// Exchange paused
  public static let expressExchangeStatusPaused = Localization.tr("Localizable", "express_exchange_status_paused")
  /// Deposit received
  public static let expressExchangeStatusReceived = Localization.tr("Localizable", "express_exchange_status_received")
  /// Waiting for deposit
  public static let expressExchangeStatusReceiving = Localization.tr("Localizable", "express_exchange_status_receiving")
  /// Awaiting deposit...
  public static let expressExchangeStatusReceivingActive = Localization.tr("Localizable", "express_exchange_status_receiving_active")
  /// Refund completed
  public static let expressExchangeStatusRefunded = Localization.tr("Localizable", "express_exchange_status_refunded")
  /// Waiting for refund
  public static let expressExchangeStatusRefunding = Localization.tr("Localizable", "express_exchange_status_refunding")
  /// Sending to you
  public static let expressExchangeStatusSending = Localization.tr("Localizable", "express_exchange_status_sending")
  /// Sending funds...
  public static let expressExchangeStatusSendingActive = Localization.tr("Localizable", "express_exchange_status_sending_active")
  /// Funds sent
  public static let expressExchangeStatusSent = Localization.tr("Localizable", "express_exchange_status_sent")
  /// Provider-sourced data. Estimated amount subject to change due to market conditions.
  public static let expressExchangeStatusSubtitle = Localization.tr("Localizable", "express_exchange_status_subtitle")
  /// Exchange status
  public static let expressExchangeStatusTitle = Localization.tr("Localizable", "express_exchange_status_title")
  /// Verification required
  public static let expressExchangeStatusVerifying = Localization.tr("Localizable", "express_exchange_status_verifying")
  /// Awaiting transaction hash
  public static let expressExchangeStatusWaitingTxHash = Localization.tr("Localizable", "express_exchange_status_waiting_tx_hash")
  /// Fetching current rates...
  public static let expressFetchBestRates = Localization.tr("Localizable", "express_fetch_best_rates")
  /// Floating rate
  public static let expressFloatingRate = Localization.tr("Localizable", "express_floating_rate")
  /// By using swap functionality, you agree with provider’s %@
  public static func expressLegalOnePlaceholder(_ p1: Any) -> String {
    return Localization.tr("Localizable", "express_legal_one_placeholder", String(describing: p1))
  }
  /// By using swap functionality, you agree with provider’s %1$@ and %2$@.
  public static func expressLegalTwoPlaceholders(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "express_legal_two_placeholders", String(describing: p1), String(describing: p2))
  }
  /// More providers will be available soon
  public static let expressMoreProvidersSoon = Localization.tr("Localizable", "express_more_providers_soon")
  /// Provider
  public static let expressProvider = Localization.tr("Localizable", "express_provider")
  /// Best rate
  public static let expressProviderBestRate = Localization.tr("Localizable", "express_provider_best_rate")
  /// FCA Warning List
  public static let expressProviderFcaWarningList = Localization.tr("Localizable", "express_provider_fca_warning_list")
  /// Competitive rate
  public static let expressProviderGreatRate = Localization.tr("Localizable", "express_provider_great_rate")
  /// Provider in FCA warning list
  public static let expressProviderInFcaWarningList = Localization.tr("Localizable", "express_provider_in_fca_warning_list")
  /// Available up to %@
  public static func expressProviderMaxAmount(_ p1: Any) -> String {
    return Localization.tr("Localizable", "express_provider_max_amount", String(describing: p1))
  }
  /// Available from %@
  public static func expressProviderMinAmount(_ p1: Any) -> String {
    return Localization.tr("Localizable", "express_provider_min_amount", String(describing: p1))
  }
  /// Unavailable for this pair
  public static let expressProviderNotAvailable = Localization.tr("Localizable", "express_provider_not_available")
  /// Permission Required
  public static let expressProviderPermissionNeeded = Localization.tr("Localizable", "express_provider_permission_needed")
  /// Recommended
  public static let expressProviderRecommended = Localization.tr("Localizable", "express_provider_recommended")
  /// Bought %@
  public static func expressStatusBought(_ p1: Any) -> String {
    return Localization.tr("Localizable", "express_status_bought", String(describing: p1))
  }
  /// Buying %@
  public static func expressStatusBuying(_ p1: Any) -> String {
    return Localization.tr("Localizable", "express_status_buying", String(describing: p1))
  }
  /// Buying %@...
  public static func expressStatusBuyingActive(_ p1: Any) -> String {
    return Localization.tr("Localizable", "express_status_buying_active", String(describing: p1))
  }
  /// Hide this transaction
  public static let expressStatusHideButtonText = Localization.tr("Localizable", "express_status_hide_button_text")
  /// If you hide this transaction, it won’t appear in the status screen anymore. If you just want to close the status screen and return later, simply swipe it away instead.
  public static let expressStatusHideDialogText = Localization.tr("Localizable", "express_status_hide_dialog_text")
  /// Hide Transaction Status?
  public static let expressStatusHideDialogTitle = Localization.tr("Localizable", "express_status_hide_dialog_title")
  /// This token is not supported. Please choose a different token to swap.
  public static let expressSwapNotSupportedText = Localization.tr("Localizable", "express_swap_not_supported_text")
  /// %@ is not supported
  public static func expressSwapNotSupportedTitle(_ p1: Any) -> String {
    return Localization.tr("Localizable", "express_swap_not_supported_title", String(describing: p1))
  }
  /// Swap with
  public static let expressSwapWith = Localization.tr("Localizable", "express_swap_with")
  /// No tokens found. Please try another request
  public static let expressTokenListEmptySearch = Localization.tr("Localizable", "express_token_list_empty_search")
  /// ID: %@
  public static func expressTransactionId(_ p1: Any) -> String {
    return Localization.tr("Localizable", "express_transaction_id", String(describing: p1))
  }
  /// Transaction ID copied
  public static let expressTransactionIdCopied = Localization.tr("Localizable", "express_transaction_id_copied")
  /// Swap any asset in your portfolio for this token
  public static let exсhangeTokenDescription = Localization.tr("Localizable", "exсhange_token_description")
  /// Higher speed means faster confirmation\nand a higher network fee. %@
  public static func feeSelectorChooseSpeedDescription(_ p1: Any) -> String {
    return Localization.tr("Localizable", "fee_selector_choose_speed_description", String(describing: p1))
  }
  /// Choose speed
  public static let feeSelectorChooseSpeedTitle = Localization.tr("Localizable", "fee_selector_choose_speed_title")
  /// Choose which token to use to pay\nthe network fee. %@
  public static func feeSelectorChooseTokenDescription(_ p1: Any) -> String {
    return Localization.tr("Localizable", "fee_selector_choose_token_description", String(describing: p1))
  }
  /// Choose token
  public static let feeSelectorChooseTokenTitle = Localization.tr("Localizable", "fee_selector_choose_token_title")
  /// Market & News
  public static let feedMarketAndNews = Localization.tr("Localizable", "feed_market_and_news")
  /// Tangem AI
  public static let feedTangemAi = Localization.tr("Localizable", "feed_tangem_ai")
  /// Trending Now
  public static let feedTrendingNow = Localization.tr("Localizable", "feed_trending_now")
  /// Tell us what functions you are missing, and we will try to help you.
  public static let feedbackPrefaceRateNegative = Localization.tr("Localizable", "feedback_preface_rate_negative")
  /// Please tell us what card or ring do you have
  public static let feedbackPrefaceScanFailed = Localization.tr("Localizable", "feedback_preface_scan_failed")
  /// Hi support team,
  public static let feedbackPrefaceSupport = Localization.tr("Localizable", "feedback_preface_support")
  /// Please tell us more about your issue. Every small detail can help.
  public static let feedbackPrefaceTxFailed = Localization.tr("Localizable", "feedback_preface_tx_failed")
  /// Backup issue
  public static let feedbackSubjectBackupProblem = Localization.tr("Localizable", "feedback_subject_backup_problem")
  /// Previously activated wallet
  public static let feedbackSubjectPreActivatedWallet = Localization.tr("Localizable", "feedback_subject_pre_activated_wallet")
  /// My suggestions
  public static let feedbackSubjectRateNegative = Localization.tr("Localizable", "feedback_subject_rate_negative")
  /// Can't scan a card/ring
  public static let feedbackSubjectScanFailed = Localization.tr("Localizable", "feedback_subject_scan_failed")
  /// Feedback
  public static let feedbackSubjectSupport = Localization.tr("Localizable", "feedback_subject_support")
  /// Tangem feedback
  public static let feedbackSubjectSupportTangem = Localization.tr("Localizable", "feedback_subject_support_tangem")
  /// Can't send a transaction
  public static let feedbackSubjectTxFailed = Localization.tr("Localizable", "feedback_subject_tx_failed")
  /// Can't push a transaction
  public static let feedbackSubjectTxPushFailed = Localization.tr("Localizable", "feedback_subject_tx_push_failed")
  /// Coin description error
  public static let feedbackTokenDescriptionError = Localization.tr("Localizable", "feedback_token_description_error")
  /// Not enough funds
  public static let gaslessNotEnoughFundsToCoverTokenFee = Localization.tr("Localizable", "gasless_not_enough_funds_to_cover_token_fee")
  /// Transaction fee
  public static let gaslessTransactionFee = Localization.tr("Localizable", "gasless_transaction_fee")
  /// An error occurred
  public static let genericError = Localization.tr("Localizable", "generic_error")
  /// An error occurred. Code: %@.
  public static func genericErrorCode(_ p1: Any) -> String {
    return Localization.tr("Localizable", "generic_error_code", String(describing: p1))
  }
  /// Requires memo
  public static let genericRequiresMemoError = Localization.tr("Localizable", "generic_requires_memo_error")
  /// Transaction
  public static let givePermissionCurrentTransaction = Localization.tr("Localizable", "give_permission_current_transaction")
  /// By approving, you allow the smart contract to use your tokens in future transactions.
  public static let givePermissionPolicyTypeFooter = Localization.tr("Localizable", "give_permission_policy_type_footer")
  /// Amount %@
  public static func givePermissionRowsAmount(_ p1: Any) -> String {
    return Localization.tr("Localizable", "give_permission_rows_amount", String(describing: p1))
  }
  /// The Approve function is needed to grant permission to another address to use a specific amount of your tokens. By design, smart contracts can't access your tokens unless you approve. By "unlocking" your tokens, you authorize the StakeKit smart contract to use them. The network's miners receive a gas fee (paid by you) to record this action on the blockchain. You can stake your token after giving approval.
  public static let givePermissionStakingFooter = Localization.tr("Localizable", "give_permission_staking_footer")
  /// To continue you need to allow Polygon smart contract to use your %@
  public static func givePermissionStakingSubtitle(_ p1: Any) -> String {
    return Localization.tr("Localizable", "give_permission_staking_subtitle", String(describing: p1))
  }
  /// To continue, grant %1@ smart contracts permission to use your %2@
  public static func givePermissionSwapSubtitle(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "give_permission_swap_subtitle", String(describing: p1), String(describing: p2))
  }
  /// Give Permission
  public static let givePermissionTitle = Localization.tr("Localizable", "give_permission_title")
  /// Unlimited
  public static let givePermissionUnlimited = Localization.tr("Localizable", "give_permission_unlimited")
  /// Addresses are generated directly on your Tangem hardware wallet — ready to use and fully protected.
  public static let hardwareWalletBackupFeatureDescription = Localization.tr("Localizable", "hardware_wallet_backup_feature_description")
  /// New Addresses
  public static let hardwareWalletBackupFeatureTitle = Localization.tr("Localizable", "hardware_wallet_backup_feature_title")
  /// Add Tangem Wallet
  public static let hardwareWalletCreateTitle = Localization.tr("Localizable", "hardware_wallet_create_title")
  /// Your private key will be generated directly inside the Tangem card and will never leave it.
  public static let hardwareWalletKeyFeatureDescription = Localization.tr("Localizable", "hardware_wallet_key_feature_description")
  /// Key Generation
  public static let hardwareWalletKeyFeatureTitle = Localization.tr("Localizable", "hardware_wallet_key_feature_title")
  /// All cryptographic operations happen inside the secure chip, certified against cloning and physical tampering.
  public static let hardwareWalletSecurityFeatureDescription = Localization.tr("Localizable", "hardware_wallet_security_feature_description")
  /// Hardware-Level Security
  public static let hardwareWalletSecurityFeatureTitle = Localization.tr("Localizable", "hardware_wallet_security_feature_title")
  /// Add Existing Wallet
  public static let homeButtonAddExistingWallet = Localization.tr("Localizable", "home_button_add_existing_wallet")
  /// Create New Wallet
  public static let homeButtonCreateNewWallet = Localization.tr("Localizable", "home_button_create_new_wallet")
  /// Order Tangem
  public static let homeButtonOrder = Localization.tr("Localizable", "home_button_order")
  /// Scan Tangem
  public static let homeButtonScan = Localization.tr("Localizable", "home_button_scan")
  /// to %@
  public static func hotCryptoAddTokenSubtitle(_ p1: Any) -> String {
    return Localization.tr("Localizable", "hot_crypto_add_token_subtitle", String(describing: p1))
  }
  /// On %@ network
  public static func hotCryptoTokenNetwork(_ p1: Any) -> String {
    return Localization.tr("Localizable", "hot_crypto_token_network", String(describing: p1))
  }
  /// Are you sure you want to cancel access code setup?
  public static let hwAccessCodeCreateAlertTitle = Localization.tr("Localizable", "hw_access_code_create_alert_title")
  /// Backup now
  public static let hwActivationNeedBackup = Localization.tr("Localizable", "hw_activation_need_backup")
  /// To complete setup, back up your wallet and secure the app with an access code.
  public static let hwActivationNeedDescription = Localization.tr("Localizable", "hw_activation_need_description")
  /// Finalize now
  public static let hwActivationNeedFinish = Localization.tr("Localizable", "hw_activation_need_finish")
  /// Finalize wallet setup
  public static let hwActivationNeedTitle = Localization.tr("Localizable", "hw_activation_need_title")
  /// Complete setup by securing the app with an access code.
  public static let hwActivationNeedWarningDescription = Localization.tr("Localizable", "hw_activation_need_warning_description")
  /// If you exit, you'll need to start over.
  public static let hwBackupAlertDescription = Localization.tr("Localizable", "hw_backup_alert_description")
  /// Are you sure you want to quit activation?
  public static let hwBackupAlertTitle = Localization.tr("Localizable", "hw_backup_alert_title")
  /// Keeps your crypto safe and offline. Slim as a credit card, safer than a bank vault.
  public static let hwBackupBannerDescription = Localization.tr("Localizable", "hw_backup_banner_description")
  /// If you do, you'll need to start over.
  public static let hwBackupCloseDescription = Localization.tr("Localizable", "hw_backup_close_description")
  /// Recover existing wallet via Google Drive backup
  public static let hwBackupGoogleDriveDescription = Localization.tr("Localizable", "hw_backup_google_drive_description")
  /// Create a secure wallet and transfer your funds for extra protection.
  public static let hwBackupHardwareCreateDescription = Localization.tr("Localizable", "hw_backup_hardware_create_description")
  /// Create new wallet
  public static let hwBackupHardwareCreateTitle = Localization.tr("Localizable", "hw_backup_hardware_create_title")
  /// Level up your security with the superior Tangem hardware wallet.
  public static let hwBackupHardwareDescription = Localization.tr("Localizable", "hw_backup_hardware_description")
  /// Hardware wallet
  public static let hwBackupHardwareTitle = Localization.tr("Localizable", "hw_backup_hardware_title")
  /// Convert your current mobile wallet into a Tangem cold wallet.
  public static let hwBackupHardwareUpgradeDescription = Localization.tr("Localizable", "hw_backup_hardware_upgrade_description")
  /// Upgrade current wallet
  public static let hwBackupHardwareUpgradeTitle = Localization.tr("Localizable", "hw_backup_hardware_upgrade_title")
  /// Recover existing wallet via iCloud backup
  public static let hwBackupIcloudDescription = Localization.tr("Localizable", "hw_backup_icloud_description")
  /// iCloud backup
  public static let hwBackupIcloudTitle = Localization.tr("Localizable", "hw_backup_icloud_title")
  /// Go to backup
  public static let hwBackupNeedAction = Localization.tr("Localizable", "hw_backup_need_action")
  /// Please back up your wallet before creating an access code.
  public static let hwBackupNeedDescription = Localization.tr("Localizable", "hw_backup_need_description")
  /// Complete the backup first
  public static let hwBackupNeedFinishFirst = Localization.tr("Localizable", "hw_backup_need_finish_first")
  /// Finalize backup first
  public static let hwBackupNeedTitle = Localization.tr("Localizable", "hw_backup_need_title")
  /// Incomplete
  public static let hwBackupNoBackup = Localization.tr("Localizable", "hw_backup_no_backup")
  /// Other methods
  public static let hwBackupSectionOtherTitle = Localization.tr("Localizable", "hw_backup_section_other_title")
  /// Save your recovery phrase in a secure place and keep it private to protect your funds, and set up an access code for additional security.
  public static let hwBackupSeedCodeDescription = Localization.tr("Localizable", "hw_backup_seed_code_description")
  /// Save your recovery phrase in a secure place and keep it private to protect your funds.
  public static let hwBackupSeedDescription = Localization.tr("Localizable", "hw_backup_seed_description")
  /// Recovery phrase
  public static let hwBackupSeedTitle = Localization.tr("Localizable", "hw_backup_seed_title")
  /// To secure your wallet with an access code, complete the backup process.
  public static let hwBackupToSecureDescription = Localization.tr("Localizable", "hw_backup_to_secure_description")
  /// To upgrade to a hardware wallet, complete the backup process.
  public static let hwBackupToUpgradeDescription = Localization.tr("Localizable", "hw_backup_to_upgrade_description")
  /// Upgrade your mobile wallet to a Tangem hardware wallet for the highest security. Import your wallet or transfer funds to a new one.
  public static let hwBackupUpgradeDescription = Localization.tr("Localizable", "hw_backup_upgrade_description")
  /// Upgrade to cold wallet
  public static let hwBackupUpgradeTitle = Localization.tr("Localizable", "hw_backup_upgrade_title")
  /// Your private keys are securely encrypted and stored on your phone
  public static let hwCreateKeysDescription = Localization.tr("Localizable", "hw_create_keys_description")
  /// Private keys stay on your device
  public static let hwCreateKeysTitle = Localization.tr("Localizable", "hw_create_keys_title")
  /// Create or restore your wallet with a recovery phrase.
  public static let hwCreateSeedDescription = Localization.tr("Localizable", "hw_create_seed_description")
  /// Seed phrase backup
  public static let hwCreateSeedTitle = Localization.tr("Localizable", "hw_create_seed_title")
  /// Create Mobile Wallet
  public static let hwCreateTitle = Localization.tr("Localizable", "hw_create_title")
  /// Transfer your mobile wallet to a Tangem card or ring anytime, securely.
  public static let hwCreateUpgradeDescription = Localization.tr("Localizable", "hw_create_upgrade_description")
  /// Upgrade to hardware wallet
  public static let hwCreateUpgradeTitle = Localization.tr("Localizable", "hw_create_upgrade_title")
  /// Import existing wallet
  public static let hwImportExistingWallet = Localization.tr("Localizable", "hw_import_existing_wallet")
  /// This recovery phrase has already been imported
  public static let hwImportSeedPhraseAlreadyImported = Localization.tr("Localizable", "hw_import_seed_phrase_already_imported")
  /// Mobile Wallet
  public static let hwMobileWallet = Localization.tr("Localizable", "hw_mobile_wallet")
  /// Forget wallet
  public static let hwRemoveWalletActionForgetTitle = Localization.tr("Localizable", "hw_remove_wallet_action_forget_title")
  /// This wallet will be permanently removed from your device
  public static let hwRemoveWalletAttentionDescription = Localization.tr("Localizable", "hw_remove_wallet_attention_description")
  /// Are you sure you want to do this?
  public static let hwRemoveWalletConfirmationTitle = Localization.tr("Localizable", "hw_remove_wallet_confirmation_title")
  /// Forget wallet
  public static let hwRemoveWalletNavTitle = Localization.tr("Localizable", "hw_remove_wallet_nav_title")
  /// Go to backup
  public static let hwRemoveWalletNotificationActionBackupGo = Localization.tr("Localizable", "hw_remove_wallet_notification_action_backup_go")
  /// View recovery phrase
  public static let hwRemoveWalletNotificationActionBackupView = Localization.tr("Localizable", "hw_remove_wallet_notification_action_backup_view")
  /// Forget wallet
  public static let hwRemoveWalletNotificationActionForget = Localization.tr("Localizable", "hw_remove_wallet_notification_action_forget")
  /// Forget anyway
  public static let hwRemoveWalletNotificationActionForgetAnyway = Localization.tr("Localizable", "hw_remove_wallet_notification_action_forget_anyway")
  /// This wallet has a backup. Ensure you can recover it before forgetting the wallet.
  public static let hwRemoveWalletNotificationDescriptionHasBackup = Localization.tr("Localizable", "hw_remove_wallet_notification_description_has_backup")
  /// If you forget this wallet without a backup, you'll permanently lose access to your funds.
  public static let hwRemoveWalletNotificationDescriptionWithoutBackup = Localization.tr("Localizable", "hw_remove_wallet_notification_description_without_backup")
  /// Are you sure you want to forget this wallet?
  public static let hwRemoveWalletNotificationTitle = Localization.tr("Localizable", "hw_remove_wallet_notification_title")
  /// I understand that if I haven't backed up my wallet before removing it, I will lose access to it.
  public static let hwRemoveWalletWarningAccess = Localization.tr("Localizable", "hw_remove_wallet_warning_access")
  /// I understand that removing my wallet does not delete it, only removes it from my device.
  public static let hwRemoveWalletWarningDevice = Localization.tr("Localizable", "hw_remove_wallet_warning_device")
  /// Upgrade
  public static let hwUpgrade = Localization.tr("Localizable", "hw_upgrade")
  /// All your addresses and balances stay fully accessible when upgrading your mobile wallet to a Tangem card or ring.
  public static let hwUpgradeBackupDescription = Localization.tr("Localizable", "hw_upgrade_backup_description")
  /// Same Addresses
  public static let hwUpgradeBackupTitle = Localization.tr("Localizable", "hw_upgrade_backup_title")
  /// Can't upgrade. A wallet already exists on this device.
  public static let hwUpgradeErrorCardAlreadyHasWallet = Localization.tr("Localizable", "hw_upgrade_error_card_already_has_wallet")
  /// Pick another device. This one can't be used for the upgrade.
  public static let hwUpgradeErrorCardKeyImport = Localization.tr("Localizable", "hw_upgrade_error_card_key_import")
  /// An error occurred during the operation.
  public static let hwUpgradeErrorWallet2CardRequired = Localization.tr("Localizable", "hw_upgrade_error_wallet2_card_required")
  /// Your funds remain safe and fully accessible during the process
  public static let hwUpgradeFundsAccessDescription = Localization.tr("Localizable", "hw_upgrade_funds_access_description")
  /// Access to funds
  public static let hwUpgradeFundsAccessTitle = Localization.tr("Localizable", "hw_upgrade_funds_access_title")
  /// After upgrading, your mobile wallet is removed from the app and stored on your Tangem hardware wallet. Your recovery phrase stays with you.
  public static let hwUpgradeGeneralSecurityDescription = Localization.tr("Localizable", "hw_upgrade_general_security_description")
  /// General security
  public static let hwUpgradeGeneralSecurityTitle = Localization.tr("Localizable", "hw_upgrade_general_security_title")
  /// Private keys will be moved from the app to your Tangem hardware wallet
  public static let hwUpgradeKeyMigrationDescription = Localization.tr("Localizable", "hw_upgrade_key_migration_description")
  /// Key migration
  public static let hwUpgradeKeyMigrationTitle = Localization.tr("Localizable", "hw_upgrade_key_migration_title")
  /// Scan device
  public static let hwUpgradeScanDevice = Localization.tr("Localizable", "hw_upgrade_scan_device")
  /// Start upgrade
  public static let hwUpgradeStartAction = Localization.tr("Localizable", "hw_upgrade_start_action")
  /// You're about to upgrade to our hardware wallet. It will keep your assets safe in cold storage.
  public static let hwUpgradeStartDescription = Localization.tr("Localizable", "hw_upgrade_start_description")
  /// Tangem Wallet
  public static let hwUpgradeStartTitle = Localization.tr("Localizable", "hw_upgrade_start_title")
  /// Upgrade to our Hardware Wallet
  public static let hwUpgradeTitle = Localization.tr("Localizable", "hw_upgrade_title")
  /// Keep your crypto safe with Tangem's top-tier hardware wallet.
  public static let hwUpgradeToColdBannerDescription = Localization.tr("Localizable", "hw_upgrade_to_cold_banner_description")
  /// Upgrade your wallet to hardware security
  public static let hwUpgradeToColdBannerTitle = Localization.tr("Localizable", "hw_upgrade_to_cold_banner_title")
  /// This information was generated with AI.\nTap here, if you find any errors.
  public static let informationGeneratedWithAi = Localization.tr("Localizable", "information_generated_with_ai")
  /// To change the access code tap the card or ring as shown above and do not remove until the end of the operation
  public static let initialMessageChangeAccessCodeBody = Localization.tr("Localizable", "initial_message_change_access_code_body")
  /// To change the passcode tap the card as shown above and do not remove until the end of the operation
  public static let initialMessageChangePasscodeBody = Localization.tr("Localizable", "initial_message_change_passcode_body")
  /// To create the wallet tap the card as shown above and do not remove until the end of the operation
  public static let initialMessageCreateWalletBody = Localization.tr("Localizable", "initial_message_create_wallet_body")
  /// To create the wallet tap the ring as shown above and do not remove until the end of the operation
  public static let initialMessageCreateWalletBodyRing = Localization.tr("Localizable", "initial_message_create_wallet_body_ring")
  /// To reset to factory settings tap the card or ring as shown above and do not remove until the end of the operation
  public static let initialMessagePurgeWalletBody = Localization.tr("Localizable", "initial_message_purge_wallet_body")
  /// Tap the card #%@ of the wallet
  public static func initialMessageResetBackupCardHeader(_ p1: Any) -> String {
    return Localization.tr("Localizable", "initial_message_reset_backup_card_header", String(describing: p1))
  }
  /// To sign tap the card or ring as shown above and do not remove until the end of the operation
  public static let initialMessageSignBody = Localization.tr("Localizable", "initial_message_sign_body")
  /// Devices with jailbreak are considered less secure. Your data may be exposed to additional risks.
  public static let jailbreakWarningMessage = Localization.tr("Localizable", "jailbreak_warning_message")
  /// Jailbreak detected
  public static let jailbreakWarningTitle = Localization.tr("Localizable", "jailbreak_warning_title")
  /// You have updated biometrics, scan your card or ring to enter
  public static let keyInvalidatedWarningDescription = Localization.tr("Localizable", "key_invalidated_warning_description")
  /// Your balance should be higher than the fee value to make a transfer
  public static let koinosInsufficientBalanceToSendKoinDescription = Localization.tr("Localizable", "koinos_insufficient_balance_to_send_koin_description")
  /// Not enough balance
  public static let koinosInsufficientBalanceToSendKoinTitle = Localization.tr("Localizable", "koinos_insufficient_balance_to_send_koin_title")
  /// You don't have enough Mana for this transaction. Please wait until the Mana is refilled. Your Mana balance is %1$@/%2$@
  public static func koinosInsufficientManaToSendKoinDescription(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "koinos_insufficient_mana_to_send_koin_description", String(describing: p1), String(describing: p2))
  }
  /// Not enough Mana
  public static let koinosInsufficientManaToSendKoinTitle = Localization.tr("Localizable", "koinos_insufficient_mana_to_send_koin_title")
  /// You can transfer only %@ due to the Mana limit imposed by the Koinos network
  public static func koinosManaExceedsKoinBalanceDescription(_ p1: Any) -> String {
    return Localization.tr("Localizable", "koinos_mana_exceeds_koin_balance_description", String(describing: p1))
  }
  /// Mana limit
  public static let koinosManaExceedsKoinBalanceTitle = Localization.tr("Localizable", "koinos_mana_exceeds_koin_balance_title")
  /// The Koinos network requires Mana for network fees. Your have %1$@/%2$@ Mana
  public static func koinosManaLevelDescription(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "koinos_mana_level_description", String(describing: p1), String(describing: p2))
  }
  /// Mana level
  public static let koinosManaLevelTitle = Localization.tr("Localizable", "koinos_mana_level_title")
  /// Please, set up an account to send email
  public static let mailErrorNoAccountsBody = Localization.tr("Localizable", "mail_error_no_accounts_body")
  /// No Mail accounts
  public static let mailErrorNoAccountsTitle = Localization.tr("Localizable", "mail_error_no_accounts_title")
  /// To begin tracking your crypto assets and transactions, add tokens
  public static let mainEmptyTokensListMessage = Localization.tr("Localizable", "main_empty_tokens_list_message")
  /// Manage tokens
  public static let mainManageTokens = Localization.tr("Localizable", "main_manage_tokens")
  /// To access all the networks you need to scan the card
  public static let mainScanCardWarningViewSubtitle = Localization.tr("Localizable", "main_scan_card_warning_view_subtitle")
  /// Scan your card or ring
  public static let mainScanCardWarningViewTitle = Localization.tr("Localizable", "main_scan_card_warning_view_title")
  /// Tokens
  public static let mainTokens = Localization.tr("Localizable", "main_tokens")
  /// Add
  public static let manageTokensAdd = Localization.tr("Localizable", "manage_tokens_add")
  /// Coin market cap
  public static let manageTokensListHeaderTitle = Localization.tr("Localizable", "manage_tokens_list_header_title")
  /// Choose networks
  public static let manageTokensNetworkSelectorTitle = Localization.tr("Localizable", "manage_tokens_network_selector_title")
  /// Couldn’t find this token, you can add it manually
  public static let manageTokensNothingFound = Localization.tr("Localizable", "manage_tokens_nothing_found")
  /// Plural format key: "%li of %#@total_wallets@"
  public static func manageTokensNumberOfWalletsIos(_ p1: Int, _ p2: Int) -> String {
    return Localization.tr("Localizable", "manage_tokens_number_of_wallets_ios", p1, p2)
  }
  /// Remove
  public static let manageTokensRemove = Localization.tr("Localizable", "manage_tokens_remove")
  /// e.g., Bitcoin
  public static let manageTokensSearchPlaceholder = Localization.tr("Localizable", "manage_tokens_search_placeholder")
  /// Your portfolio has been updated
  public static let manageTokensToastPortfolioUpdated = Localization.tr("Localizable", "manage_tokens_toast_portfolio_updated")
  /// The selected token is currently unavailable for actions within the crypto wallet. But worry not, you can express your interest by upvoting it.
  public static let manageTokensUnavailableDescription = Localization.tr("Localizable", "manage_tokens_unavailable_description")
  /// Upvote
  public static let manageTokensUnavailableVote = Localization.tr("Localizable", "manage_tokens_unavailable_vote")
  /// Choose wallet
  public static let manageTokensWalletSelectorTitle = Localization.tr("Localizable", "manage_tokens_wallet_selector_title")
  /// The wallet doesn't support more than one network
  public static let manageTokensWalletSupportOnlyOneNetworkTitle = Localization.tr("Localizable", "manage_tokens_wallet_support_only_one_network_title")
  /// About coin
  public static let marketsAboutCoinHeader = Localization.tr("Localizable", "markets_about_coin_header")
  /// To buy, exchange, or receive this asset, add it to your portfolio
  public static let marketsAddToMyPortfolioDescription = Localization.tr("Localizable", "markets_add_to_my_portfolio_description")
  /// This asset is currently not supported in the wallet
  public static let marketsAddToMyPortfolioUnavailableDescription = Localization.tr("Localizable", "markets_add_to_my_portfolio_unavailable_description")
  /// This asset is not available for this wallet
  public static let marketsAddToMyPortfolioUnavailableForWalletDescription = Localization.tr("Localizable", "markets_add_to_my_portfolio_unavailable_for_wallet_description")
  /// Add
  public static let marketsAddToken = Localization.tr("Localizable", "markets_add_token")
  /// APY %@
  public static func marketsApyPlaceholder(_ p1: Any) -> String {
    return Localization.tr("Localizable", "markets_apy_placeholder", String(describing: p1))
  }
  /// Available networks
  public static let marketsAvailableNetworks = Localization.tr("Localizable", "markets_available networks")
  /// My portfolio
  public static let marketsCommonMyPortfolio = Localization.tr("Localizable", "markets_common_my_portfolio")
  /// Market
  public static let marketsCommonTitle = Localization.tr("Localizable", "markets_common_title")
  /// Earn with Tangem
  public static let marketsEarnCommonTitle = Localization.tr("Localizable", "markets_earn_common_title")
  /// To generate addresses for selected networks, you must scan your Tangem Wallet card or ring
  public static let marketsGenerateAddressesNotification = Localization.tr("Localizable", "markets_generate_addresses_notification")
  /// To add tokens pull this up or tap the search bar
  public static let marketsHint = Localization.tr("Localizable", "markets_hint")
  /// This section’s data is sourced from the following networks: %@
  public static func marketsInsightsInfoDescriptionMessage(_ p1: Any) -> String {
    return Localization.tr("Localizable", "markets_insights_info_description_message", String(describing: p1))
  }
  /// Unable to load the data…
  public static let marketsLoadingErrorTitle = Localization.tr("Localizable", "markets_loading_error_title")
  /// No data
  public static let marketsLoadingNoDataTitle = Localization.tr("Localizable", "markets_loading_no_data_title")
  /// Market Pulse
  public static let marketsPulseCommonTitle = Localization.tr("Localizable", "markets_pulse_common_title")
  /// Quick actions
  public static let marketsQuickActions = Localization.tr("Localizable", "markets_quick_actions")
  /// Search tokens
  public static let marketsSearchHeaderTitle = Localization.tr("Localizable", "markets_search_header_title")
  /// Result
  public static let marketsSearchResultTitle = Localization.tr("Localizable", "markets_search_result_title")
  /// See tokens under 100k USD market cap
  public static let marketsSearchSeeTokensUnder100k = Localization.tr("Localizable", "markets_search_see_tokens_under_100k")
  /// Show tokens
  public static let marketsSearchShowTokens = Localization.tr("Localizable", "markets_search_show_tokens")
  /// No result
  public static let marketsSearchTokenNoResultTitle = Localization.tr("Localizable", "markets_search_token_no_result_title")
  /// Select network
  public static let marketsSelectNetwork = Localization.tr("Localizable", "markets_select_network")
  /// Select wallet
  public static let marketsSelectWallet = Localization.tr("Localizable", "markets_select_wallet")
  /// 1m
  public static let marketsSelectorInterval1mTitle = Localization.tr("Localizable", "markets_selector_interval_1m_title")
  /// 1y
  public static let marketsSelectorInterval1yTitle = Localization.tr("Localizable", "markets_selector_interval_1y_title")
  /// 24h
  public static let marketsSelectorInterval24hTitle = Localization.tr("Localizable", "markets_selector_interval_24h_title")
  /// 3m
  public static let marketsSelectorInterval3mTitle = Localization.tr("Localizable", "markets_selector_interval_3m_title")
  /// 6m
  public static let marketsSelectorInterval6mTitle = Localization.tr("Localizable", "markets_selector_interval_6m_title")
  /// 7d
  public static let marketsSelectorInterval7dTitle = Localization.tr("Localizable", "markets_selector_interval_7d_title")
  /// All
  public static let marketsSelectorIntervalAllTitle = Localization.tr("Localizable", "markets_selector_interval_all_title")
  /// Experienced buyers
  public static let marketsSortByExperiencedBuyersTitle = Localization.tr("Localizable", "markets_sort_by_experienced_buyers_title")
  /// Market Cap
  public static let marketsSortByRatingTitle = Localization.tr("Localizable", "markets_sort_by_rating_title")
  /// Sort By
  public static let marketsSortByTitle = Localization.tr("Localizable", "markets_sort_by_title")
  /// Gainers
  public static let marketsSortByTopGainersTitle = Localization.tr("Localizable", "markets_sort_by_top_gainers_title")
  /// Losers
  public static let marketsSortByTopLosersTitle = Localization.tr("Localizable", "markets_sort_by_top_losers_title")
  /// Trending
  public static let marketsSortByTrendingTitle = Localization.tr("Localizable", "markets_sort_by_trending_title")
  /// Yield Mode
  public static let marketsSortByYieldModeTitle = Localization.tr("Localizable", "markets_sort_by_yield_mode_title")
  /// Staking is the easiest way to receive rewards on your crypto. %@
  public static func marketsStakingBannerDescriptionPlaceholder(_ p1: Any) -> String {
    return Localization.tr("Localizable", "markets_staking_banner_description_placeholder", String(describing: p1))
  }
  /// Earn up to %@ APY
  public static func marketsStakingBannerTitle(_ p1: Any) -> String {
    return Localization.tr("Localizable", "markets_staking_banner_title", String(describing: p1))
  }
  /// Token Added
  public static let marketsTokenAdded = Localization.tr("Localizable", "markets_token_added")
  /// About %@
  public static func marketsTokenDetailsAboutTokenTitle(_ p1: Any) -> String {
    return Localization.tr("Localizable", "markets_token_details_about_token_title", String(describing: p1))
  }
  /// Plural format key: "%#@format@"
  public static func marketsTokenDetailsAmountExchanges(_ p1: Int) -> String {
    return Localization.tr("Localizable", "markets_token_details_amount_exchanges", p1)
  }
  /// Plural format key: "%#@format@"
  public static func marketsTokenDetailsBasedOnRatings(_ p1: Int) -> String {
    return Localization.tr("Localizable", "markets_token_details_based_on_ratings", p1)
  }
  /// Website
  public static let marketsTokenDetailsBlockchainSite = Localization.tr("Localizable", "markets_token_details_blockchain_site")
  /// Buy pressure
  public static let marketsTokenDetailsBuyPressure = Localization.tr("Localizable", "markets_token_details_buy_pressure")
  /// The difference between buyers volume and sellers volume
  public static let marketsTokenDetailsBuyPressureDescription = Localization.tr("Localizable", "markets_token_details_buy_pressure_description")
  /// Buy pressure
  public static let marketsTokenDetailsBuyPressureFull = Localization.tr("Localizable", "markets_token_details_buy_pressure_full")
  /// Circulating supply
  public static let marketsTokenDetailsCirculatingSupply = Localization.tr("Localizable", "markets_token_details_circulating_supply")
  /// The total number of coins that are available for trading and are circulating in the market
  public static let marketsTokenDetailsCirculatingSupplyDescription = Localization.tr("Localizable", "markets_token_details_circulating_supply_description")
  /// Circulating supply
  public static let marketsTokenDetailsCirculatingSupplyFull = Localization.tr("Localizable", "markets_token_details_circulating_supply_full")
  /// No exchanges found
  public static let marketsTokenDetailsEmptyExchanges = Localization.tr("Localizable", "markets_token_details_empty_exchanges")
  /// Exchange
  public static let marketsTokenDetailsExchange = Localization.tr("Localizable", "markets_token_details_exchange")
  /// Caution
  public static let marketsTokenDetailsExchangeTrustScoreCaution = Localization.tr("Localizable", "markets_token_details_exchange_trust_score_caution")
  /// Risky
  public static let marketsTokenDetailsExchangeTrustScoreRisky = Localization.tr("Localizable", "markets_token_details_exchange_trust_score_risky")
  /// Trusted
  public static let marketsTokenDetailsExchangeTrustScoreTrusted = Localization.tr("Localizable", "markets_token_details_exchange_trust_score_trusted")
  /// Exchanges
  public static let marketsTokenDetailsExchangesTitle = Localization.tr("Localizable", "markets_token_details_exchanges_title")
  /// Experienced buyers
  public static let marketsTokenDetailsExperiencedBuyers = Localization.tr("Localizable", "markets_token_details_experienced_buyers")
  /// Net buyers with the additional requirement of having at least 100 outgoing transactions
  public static let marketsTokenDetailsExperiencedBuyersDescription = Localization.tr("Localizable", "markets_token_details_experienced_buyers_description")
  /// Active Buyers
  public static let marketsTokenDetailsExperiencedBuyersFull = Localization.tr("Localizable", "markets_token_details_experienced_buyers_full")
  /// Fully diluted valuation
  public static let marketsTokenDetailsFullyDilutedValuation = Localization.tr("Localizable", "markets_token_details_fully_diluted_valuation")
  /// The total theoretical value of a cryptocurrency if all coins that could exist are in circulation, including those not currently circulating
  public static let marketsTokenDetailsFullyDilutedValuationDescription = Localization.tr("Localizable", "markets_token_details_fully_diluted_valuation_description")
  /// Fully diluted valuation
  public static let marketsTokenDetailsFullyDilutedValuationFull = Localization.tr("Localizable", "markets_token_details_fully_diluted_valuation_full")
  /// Genesis date
  public static let marketsTokenDetailsGenesisDate = Localization.tr("Localizable", "markets_token_details_genesis_date")
  /// High
  public static let marketsTokenDetailsHigh = Localization.tr("Localizable", "markets_token_details_high")
  /// Holders
  public static let marketsTokenDetailsHolders = Localization.tr("Localizable", "markets_token_details_holders")
  /// The change in the number of token holders within a specific timeframe
  public static let marketsTokenDetailsHoldersDescription = Localization.tr("Localizable", "markets_token_details_holders_description")
  /// Holders
  public static let marketsTokenDetailsHoldersFull = Localization.tr("Localizable", "markets_token_details_holders_full")
  /// Insights
  public static let marketsTokenDetailsInsights = Localization.tr("Localizable", "markets_token_details_insights")
  /// Links
  public static let marketsTokenDetailsLinks = Localization.tr("Localizable", "markets_token_details_links")
  /// Liquidity
  public static let marketsTokenDetailsLiquidity = Localization.tr("Localizable", "markets_token_details_liquidity")
  /// The change in how much liquidity is available for the token during the specified timeframe
  public static let marketsTokenDetailsLiquidityDescription = Localization.tr("Localizable", "markets_token_details_liquidity_description")
  /// Liquidity
  public static let marketsTokenDetailsLiquidityFull = Localization.tr("Localizable", "markets_token_details_liquidity_full")
  /// Liquidity index
  public static let marketsTokenDetailsLiquidityIndex = Localization.tr("Localizable", "markets_token_details_liquidity_index")
  /// Listed on
  public static let marketsTokenDetailsListedOn = Localization.tr("Localizable", "markets_token_details_listed_on")
  /// Low
  public static let marketsTokenDetailsLow = Localization.tr("Localizable", "markets_token_details_low")
  /// Market cap
  public static let marketsTokenDetailsMarketCapitalization = Localization.tr("Localizable", "markets_token_details_market_capitalization")
  /// The total market value of a cryptocurrency, calculated by multiplying the current price of the coin by the total number of coins in circulation
  public static let marketsTokenDetailsMarketCapitalizationDescription = Localization.tr("Localizable", "markets_token_details_market_capitalization_description")
  /// Market cap
  public static let marketsTokenDetailsMarketCapitalizationFull = Localization.tr("Localizable", "markets_token_details_market_capitalization_full")
  /// Market position
  public static let marketsTokenDetailsMarketRating = Localization.tr("Localizable", "markets_token_details_market_rating")
  /// Position in crypto rating between all coins based on market capitalization
  public static let marketsTokenDetailsMarketRatingDescription = Localization.tr("Localizable", "markets_token_details_market_rating_description")
  /// Market position
  public static let marketsTokenDetailsMarketRatingFull = Localization.tr("Localizable", "markets_token_details_market_rating_full")
  /// Max supply
  public static let marketsTokenDetailsMaxSupply = Localization.tr("Localizable", "markets_token_details_max_supply")
  /// The maximum number of coins or tokens that can ever exist for a particular cryptocurrency
  public static let marketsTokenDetailsMaxSupplyDescription = Localization.tr("Localizable", "markets_token_details_max_supply_description")
  /// Max supply
  public static let marketsTokenDetailsMaxSupplyFull = Localization.tr("Localizable", "markets_token_details_max_supply_full")
  /// Metrics
  public static let marketsTokenDetailsMetrics = Localization.tr("Localizable", "markets_token_details_metrics")
  /// Official links
  public static let marketsTokenDetailsOfficialLinks = Localization.tr("Localizable", "markets_token_details_official_links")
  /// Price performance
  public static let marketsTokenDetailsPricePerformance = Localization.tr("Localizable", "markets_token_details_price_performance")
  /// Repository
  public static let marketsTokenDetailsRepository = Localization.tr("Localizable", "markets_token_details_repository")
  /// Security score
  public static let marketsTokenDetailsSecurityScore = Localization.tr("Localizable", "markets_token_details_security_score")
  /// Security score of a token is a metric that assesses the security level of a blockchain or token based on various factors and is compiled from the sources listed below.
  public static let marketsTokenDetailsSecurityScoreDescription = Localization.tr("Localizable", "markets_token_details_security_score_description")
  /// Social
  public static let marketsTokenDetailsSocial = Localization.tr("Localizable", "markets_token_details_social")
  /// Total supply
  public static let marketsTokenDetailsTotalSupply = Localization.tr("Localizable", "markets_token_details_total_supply")
  /// The maximum number of coins or tokens that can ever exist for a particular cryptocurrency
  public static let marketsTokenDetailsTotalSupplyDescription = Localization.tr("Localizable", "markets_token_details_total_supply_description")
  /// Total supply
  public static let marketsTokenDetailsTotalSupplyFull = Localization.tr("Localizable", "markets_token_details_total_supply_full")
  /// Trading volume (24h)
  public static let marketsTokenDetailsTradingVolume = Localization.tr("Localizable", "markets_token_details_trading_volume")
  /// The total amount of a cryptocurrency that has been traded within the last 24 hours, indicating the level of activity and liquidity in the market
  public static let marketsTokenDetailsTradingVolume24hDescription = Localization.tr("Localizable", "markets_token_details_trading_volume_24h_description")
  /// Trading volume (24h)
  public static let marketsTokenDetailsTradingVolumeFull = Localization.tr("Localizable", "markets_token_details_trading_volume_full")
  /// Volume
  public static let marketsTokenDetailsVolume = Localization.tr("Localizable", "markets_token_details_volume")
  /// Pull this up or tap the search bar to add tokens directly from the market
  public static let marketsTooltipMessage = Localization.tr("Localizable", "markets_tooltip_message")
  /// Add tokens
  public static let marketsTooltipTitle = Localization.tr("Localizable", "markets_tooltip_title")
  /// Add more tokens
  public static let marketsTooltipV2Title = Localization.tr("Localizable", "markets_tooltip_v2_title")
  /// Power up your assets while supplying them with instant access. %@
  public static func marketsYieldSupplyBannerDescription(_ p1: Any) -> String {
    return Localization.tr("Localizable", "markets_yield_supply_banner_description", String(describing: p1))
  }
  /// Activate Yield Mode
  public static let marketsYieldSupplyBannerTitle = Localization.tr("Localizable", "markets_yield_supply_banner_title")
  /// You must update to %1$@  before creating a mobile wallet
  public static func mobileWalletRequiresMinOsWarningBody(_ p1: Any) -> String {
    return Localization.tr("Localizable", "mobile_wallet_requires_min_os_warning_body", String(describing: p1))
  }
  /// Mobile Wallet requires %1$@ or later
  public static func mobileWalletRequiresMinOsWarningTitle(_ p1: Any) -> String {
    return Localization.tr("Localizable", "mobile_wallet_requires_min_os_warning_title", String(describing: p1))
  }
  /// All news
  public static let newsAllNews = Localization.tr("Localizable", "news_all_news")
  /// Like
  public static let newsLike = Localization.tr("Localizable", "news_like")
  /// Plural format key: "%#@format@"
  public static func newsPublishedHoursAgo(_ p1: Int) -> String {
    return Localization.tr("Localizable", "news_published_hours_ago", p1)
  }
  /// Plural format key: "%#@format@"
  public static func newsPublishedMinutesAgo(_ p1: Int) -> String {
    return Localization.tr("Localizable", "news_published_minutes_ago", p1)
  }
  /// Quick recap
  public static let newsQuickRecap = Localization.tr("Localizable", "news_quick_recap")
  /// News
  public static let newsRelatedNews = Localization.tr("Localizable", "news_related_news")
  /// Related tokens
  public static let newsRelatedTokens = Localization.tr("Localizable", "news_related_tokens")
  /// Related news
  public static let newsSources = Localization.tr("Localizable", "news_sources")
  /// Stay in the loop
  public static let newsStayInTheLoop = Localization.tr("Localizable", "news_stay_in_the_loop")
  /// About NFT
  public static let nftAboutTitle = Localization.tr("Localizable", "nft_about_title")
  /// NFT asset
  public static let nftAsset = Localization.tr("Localizable", "nft_asset")
  /// Plural format key: "%#@format@"
  public static func nftCollectionsCount(_ p1: Int) -> String {
    return Localization.tr("Localizable", "nft_collections_count", p1)
  }
  /// NFTs sent to your wallet address will show up here.
  public static let nftCollectionsEmptyDescription = Localization.tr("Localizable", "nft_collections_empty_description")
  /// No collections, yet
  public static let nftCollectionsEmptyTitle = Localization.tr("Localizable", "nft_collections_empty_title")
  /// Receive NFT
  public static let nftCollectionsReceive = Localization.tr("Localizable", "nft_collections_receive")
  /// NFT collections
  public static let nftCollectionsTitle = Localization.tr("Localizable", "nft_collections_title")
  /// Some data may not load
  public static let nftCollectionsWarningSubtitle = Localization.tr("Localizable", "nft_collections_warning_subtitle")
  /// Temporary loading problems
  public static let nftCollectionsWarningTitle = Localization.tr("Localizable", "nft_collections_warning_title")
  /// Base information
  public static let nftDetailsBaseInformation = Localization.tr("Localizable", "nft_details_base_information")
  /// Chain
  public static let nftDetailsChain = Localization.tr("Localizable", "nft_details_chain")
  /// Contract Address
  public static let nftDetailsContractAddress = Localization.tr("Localizable", "nft_details_contract_address")
  /// Chain is the blockchain where the NFT exists.
  public static let nftDetailsInfoChain = Localization.tr("Localizable", "nft_details_info_chain")
  /// The contract address is a unique identifier for the smart contract that governs the tokens on the blockchain
  public static let nftDetailsInfoContractAddress = Localization.tr("Localizable", "nft_details_info_contract_address")
  /// A label that describes how rare the NFT is. The lower the value, the more unique the NFT.
  public static let nftDetailsInfoRarityLabel = Localization.tr("Localizable", "nft_details_info_rarity_label")
  /// The position of an NFT in the rarity ranking among other tokens. The higher the rank, the rarer and more valuable the NFT.
  public static let nftDetailsInfoRarityRank = Localization.tr("Localizable", "nft_details_info_rarity_rank")
  /// The token address is a unique identifier for the token on the blockchain, allowing tracking of transactions and ownership
  public static let nftDetailsInfoTokenAddress = Localization.tr("Localizable", "nft_details_info_token_address")
  /// The token ID is a unique identifier assigned to each token, distinguishing it from others in the collection
  public static let nftDetailsInfoTokenId = Localization.tr("Localizable", "nft_details_info_token_id")
  /// Token standard defines what type of token it is and how it works with different wallets and platforms
  public static let nftDetailsInfoTokenStandard = Localization.tr("Localizable", "nft_details_info_token_standard")
  /// Last sale price
  public static let nftDetailsLastSalePrice = Localization.tr("Localizable", "nft_details_last_sale_price")
  /// Rarity label
  public static let nftDetailsRarityLabel = Localization.tr("Localizable", "nft_details_rarity_label")
  /// Rarity rank
  public static let nftDetailsRarityRank = Localization.tr("Localizable", "nft_details_rarity_rank")
  /// Token Address
  public static let nftDetailsTokenAddress = Localization.tr("Localizable", "nft_details_token_address")
  /// Token ID
  public static let nftDetailsTokenId = Localization.tr("Localizable", "nft_details_token_id")
  /// Token Standard
  public static let nftDetailsTokenStandard = Localization.tr("Localizable", "nft_details_token_standard")
  /// Traits
  public static let nftDetailsTraits = Localization.tr("Localizable", "nft_details_traits")
  /// No results. Please try another request.
  public static let nftEmptySearch = Localization.tr("Localizable", "nft_empty_search")
  /// No collection
  public static let nftNoCollection = Localization.tr("Localizable", "nft_no_collection")
  /// Available
  public static let nftReceiveAvailableSectionTitle = Localization.tr("Localizable", "nft_receive_available_section_title")
  /// Choose network
  public static let nftReceiveChooseNetwork = Localization.tr("Localizable", "nft_receive_choose_network")
  /// Receive NFT
  public static let nftReceiveTitle = Localization.tr("Localizable", "nft_receive_title")
  /// You haven't added this network yet. To receive NFTs, add it to your portfolio.
  public static let nftReceiveUnavailableAssetWarningMessage = Localization.tr("Localizable", "nft_receive_unavailable_asset_warning_message")
  /// Network not added
  public static let nftReceiveUnavailableAssetWarningTitle = Localization.tr("Localizable", "nft_receive_unavailable_asset_warning_title")
  /// Not Added
  public static let nftReceiveUnavailableSectionTitle = Localization.tr("Localizable", "nft_receive_unavailable_section_title")
  /// Unsupported NFT types
  public static let nftReceiveUnsupportedTypes = Localization.tr("Localizable", "nft_receive_unsupported_types")
  /// cNFTs and pNFTs are not supported yet. Please don't send them to your wallet.
  public static let nftReceiveUnsupportedTypesDescription = Localization.tr("Localizable", "nft_receive_unsupported_types_description")
  /// Send NFT
  public static let nftSend = Localization.tr("Localizable", "nft_send")
  /// Traits
  public static let nftTraitsTitle = Localization.tr("Localizable", "nft_traits_title")
  /// Untitled collection
  public static let nftUntitledCollection = Localization.tr("Localizable", "nft_untitled_collection")
  /// Plural format key: "%#@nfts_count@ in %#@collections_count@"
  public static func nftWalletCountIos(_ p1: Int, _ p2: Int) -> String {
    return Localization.tr("Localizable", "nft_wallet_count_ios", p1, p2)
  }
  /// Tap here to receive first NFT
  public static let nftWalletReceiveNft = Localization.tr("Localizable", "nft_wallet_receive_nft")
  /// NFT collections
  public static let nftWalletTitle = Localization.tr("Localizable", "nft_wallet_title")
  /// Unable to load the data
  public static let nftWalletUnableToLoad = Localization.tr("Localizable", "nft_wallet_unable_to_load")
  /// To use the %1$@ network, you must pay the account reserve (%2$@ %3$@), which locks up and hides that amount indefinitely
  public static func noAccountGeneric(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return Localization.tr("Localizable", "no_account_generic", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// Destination account is not active. Send %@ or more to activate the account.
  public static func noAccountPolkadot(_ p1: Any) -> String {
    return Localization.tr("Localizable", "no_account_polkadot", String(describing: p1))
  }
  /// To create account send funds to this address
  public static let noAccountSendToCreate = Localization.tr("Localizable", "no_account_send_to_create")
  /// The destination account does not have a trustline for the asset being sent.
  public static let noTrustlineXlmAsset = Localization.tr("Localizable", "no_trustline_xlm_asset")
  /// Get $10 in BTC with every wallet\nHurry!
  public static let notificationBlackFridayText = Localization.tr("Localizable", "notification_black_friday_text")
  /// Black Friday: up to 30%% OFF
  public static let notificationBlackFridayTitle = Localization.tr("Localizable", "notification_black_friday_title")
  /// Let’s go
  public static let notificationOnePlusOneButton = Localization.tr("Localizable", "notification_one_plus_one_button")
  /// Limited time!
  public static let notificationOnePlusOneText = Localization.tr("Localizable", "notification_one_plus_one_text")
  /// 1+1: Buy One Wallet, Get 50%% OFF
  public static let notificationOnePlusOneTitle = Localization.tr("Localizable", "notification_one_plus_one_title")
  /// Join Now
  public static let notificationReferralPromoButton = Localization.tr("Localizable", "notification_referral_promo_button")
  /// Buy crypto
  public static let notificationSepaButton = Localization.tr("Localizable", "notification_sepa_button")
  /// Enjoy **0%% fees** when purchasing crypto via SEPA transfers.
  public static let notificationSepaText = Localization.tr("Localizable", "notification_sepa_text")
  /// Buy Crypto with SEPA
  public static let notificationSepaTitle = Localization.tr("Localizable", "notification_sepa_title")
  /// Join the waitlist and get a payment card unlike any other
  public static let notificationVisaWaitlistPromoText = Localization.tr("Localizable", "notification_visa_waitlist_promo_text")
  /// Tangem Visa Card
  public static let notificationVisaWaitlistPromoTitle = Localization.tr("Localizable", "notification_visa_waitlist_promo_title")
  /// Terms and conditions
  public static let notificationYieldPromoButton = Localization.tr("Localizable", "notification_yield_promo_button")
  /// Deposit $100+, hold for 30 days, get $10
  public static let notificationYieldPromoText = Localization.tr("Localizable", "notification_yield_promo_text")
  /// Join the Yield Mode Campaign!
  public static let notificationYieldPromoTitle = Localization.tr("Localizable", "notification_yield_promo_title")
  /// Set up a single access code to protect all your devices.
  public static let onboardingAccessCodeFeature1Description = Localization.tr("Localizable", "onboarding_access_code_feature_1_description")
  /// Protect
  public static let onboardingAccessCodeFeature1Title = Localization.tr("Localizable", "onboarding_access_code_feature_1_title")
  /// Set an individual access code for each card or ring later.
  public static let onboardingAccessCodeFeature2Description = Localization.tr("Localizable", "onboarding_access_code_feature_2_description")
  /// Personalize
  public static let onboardingAccessCodeFeature2Title = Localization.tr("Localizable", "onboarding_access_code_feature_2_title")
  /// Restore the access code with a linked card or ring. Don't keep all your devices in one place.
  public static let onboardingAccessCodeFeature3Description = Localization.tr("Localizable", "onboarding_access_code_feature_3_description")
  /// Restore
  public static let onboardingAccessCodeFeature3Title = Localization.tr("Localizable", "onboarding_access_code_feature_3_title")
  /// Choose any word, phrase, or number you want as your access code
  public static let onboardingAccessCodeHint = Localization.tr("Localizable", "onboarding_access_code_hint")
  /// Create Access Code
  public static let onboardingAccessCodeIntroTitle = Localization.tr("Localizable", "onboarding_access_code_intro_title")
  /// Enter your access code one more time to avoid a mistake
  public static let onboardingAccessCodeRepeatCodeHint = Localization.tr("Localizable", "onboarding_access_code_repeat_code_hint")
  /// Re-enter your Access Code
  public static let onboardingAccessCodeRepeatCodeTitle = Localization.tr("Localizable", "onboarding_access_code_repeat_code_title")
  /// Access code must be at least 4 characters long
  public static let onboardingAccessCodeTooShort = Localization.tr("Localizable", "onboarding_access_code_too_short")
  /// Entered access code didn't match the initial access code
  public static let onboardingAccessCodesDoesntMatch = Localization.tr("Localizable", "onboarding_access_codes_doesnt_match")
  /// Please repeat the operation. The card will be reset to factory settings.
  public static let onboardingActivationErrorMessage = Localization.tr("Localizable", "onboarding_activation_error_message")
  /// Activation error
  public static let onboardingActivationErrorTitle = Localization.tr("Localizable", "onboarding_activation_error_title")
  /// Add tokens
  public static let onboardingAddTokens = Localization.tr("Localizable", "onboarding_add_tokens")
  /// You've added one backup card or ring. Once backup is finalized, you can't add more devices. If you have one more card or ring, add it now. Do you want to continue?
  public static let onboardingAlertMessageNotMaxBackupCardsAdded = Localization.tr("Localizable", "onboarding_alert_message_not_max_backup_cards_added")
  /// iPhone 7/7+ is not able to create a backup for Tangem Wallet due to some system limitations. Please use another phone to perform this operation. All other functions work stably.
  public static let onboardingAlertMessageOldDevice = Localization.tr("Localizable", "onboarding_alert_message_old_device")
  /// The backup is partially complete and can't be quit now.
  public static let onboardingBackupExitWarning = Localization.tr("Localizable", "onboarding_backup_exit_warning")
  /// A passphrase is an optional security feature that adds a word or phrase to your recovery phrase, creating a new set of wallet addresses for extra protection.
  public static let onboardingBottomSheetPassphraseDescription = Localization.tr("Localizable", "onboarding_bottom_sheet_passphrase_description")
  /// Add a card or ring
  public static let onboardingButtonAddBackupCard = Localization.tr("Localizable", "onboarding_button_add_backup_card")
  /// Scan card
  public static let onboardingButtonBackupCard = Localization.tr("Localizable", "onboarding_button_backup_card")
  /// Backup now
  public static let onboardingButtonBackupNow = Localization.tr("Localizable", "onboarding_button_backup_now")
  /// Scan ring
  public static let onboardingButtonBackupRing = Localization.tr("Localizable", "onboarding_button_backup_ring")
  /// Continue to my wallet
  public static let onboardingButtonContinueWallet = Localization.tr("Localizable", "onboarding_button_continue_wallet")
  /// Finalize backup
  public static let onboardingButtonFinalizeBackup = Localization.tr("Localizable", "onboarding_button_finalize_backup")
  /// Scan primary card or ring
  public static let onboardingButtonScanOriginCard = Localization.tr("Localizable", "onboarding_button_scan_origin_card")
  /// Skip for later
  public static let onboardingButtonSkipBackup = Localization.tr("Localizable", "onboarding_button_skip_backup")
  /// How does it work?
  public static let onboardingButtonWhatDoesItMean = Localization.tr("Localizable", "onboarding_button_what_does_it_mean")
  /// Let's generate all the keys on your card or ring and create a secure wallet
  public static let onboardingCreateWalletBody = Localization.tr("Localizable", "onboarding_create_wallet_body")
  /// Create wallet
  public static let onboardingCreateWalletButtonCreateWallet = Localization.tr("Localizable", "onboarding_create_wallet_button_create_wallet")
  /// Other options
  public static let onboardingCreateWalletOptionsButtonOptions = Localization.tr("Localizable", "onboarding_create_wallet_options_button_options")
  /// Your keys will be securely generated inside the chip. There is no seed phrase, which means nobody can export or steal it.
  public static let onboardingCreateWalletOptionsMessage = Localization.tr("Localizable", "onboarding_create_wallet_options_message")
  /// Generate keys privately
  public static let onboardingCreateWalletOptionsTitle = Localization.tr("Localizable", "onboarding_create_wallet_options_title")
  /// Your card is activated and ready to be used
  public static let onboardingDoneBody = Localization.tr("Localizable", "onboarding_done_body")
  /// Success!
  public static let onboardingDoneHeader = Localization.tr("Localizable", "onboarding_done_header")
  /// Your wallet is set up and ready to use!
  public static let onboardingDoneWallet = Localization.tr("Localizable", "onboarding_done_wallet")
  /// In this case, you will need to start from the beginning.
  public static let onboardingExitAlertMessage = Localization.tr("Localizable", "onboarding_exit_alert_message")
  /// Do you want to exit the activation process?
  public static let onboardingExitAlertTitle = Localization.tr("Localizable", "onboarding_exit_alert_title")
  /// Getting started
  public static let onboardingGettingStarted = Localization.tr("Localizable", "onboarding_getting_started")
  /// Another wallet has already been created on the card you're trying to add. If you have funds in this wallet, please withdraw it and then reset this card and add it as a backup.
  public static let onboardingLinkingErrorCardWithWallets = Localization.tr("Localizable", "onboarding_linking_error_card_with_wallets")
  /// Save your wallet
  public static let onboardingNavbarSaveWallet = Localization.tr("Localizable", "onboarding_navbar_save_wallet")
  /// Creating a backup
  public static let onboardingNavbarTitleCreatingBackup = Localization.tr("Localizable", "onboarding_navbar_title_creating_backup")
  /// Biometrics
  public static let onboardingNavbarUpgradeWalletBiometrics = Localization.tr("Localizable", "onboarding_navbar_upgrade_wallet_biometrics")
  /// Read more about seed phrase
  public static let onboardingSeedButtonReadMore = Localization.tr("Localizable", "onboarding_seed_button_read_more")
  /// Plural format key: "%#@format@"
  public static func onboardingSeedGenerateMessageWordsCount(_ p1: Int) -> String {
    return Localization.tr("Localizable", "onboarding_seed_generate_message_words_count", p1)
  }
  /// Your seed phrase
  public static let onboardingSeedGenerateTitle = Localization.tr("Localizable", "onboarding_seed_generate_title")
  /// Plural format key: "%#@format@"
  public static func onboardingSeedGenerateWordsCount(_ p1: Int) -> String {
    return Localization.tr("Localizable", "onboarding_seed_generate_words_count", p1)
  }
  /// To import your wallet, enter your seed phrase in the field below
  public static let onboardingSeedImportMessage = Localization.tr("Localizable", "onboarding_seed_import_message")
  /// Generate seed phrase
  public static let onboardingSeedIntroButtonGenerate = Localization.tr("Localizable", "onboarding_seed_intro_button_generate")
  /// Import wallet
  public static let onboardingSeedIntroButtonImport = Localization.tr("Localizable", "onboarding_seed_intro_button_import")
  /// A seed phrase is a series of words that allows you to recover your wallet. Unlike the keys generated by the card or ring, seed phrases are unprotected and can be copied and stolen. Use this option at your own risk.
  public static let onboardingSeedIntroMessage = Localization.tr("Localizable", "onboarding_seed_intro_message")
  /// Use seed phrase
  public static let onboardingSeedIntroTitle = Localization.tr("Localizable", "onboarding_seed_intro_title")
  /// Invalid seed phrase. Please check the word order.
  public static let onboardingSeedMnemonicInvalidChecksum = Localization.tr("Localizable", "onboarding_seed_mnemonic_invalid_checksum")
  /// Invalid seed phrase. Please check your spelling.
  public static let onboardingSeedMnemonicWrongWords = Localization.tr("Localizable", "onboarding_seed_mnemonic_wrong_words")
  /// Legacy
  public static let onboardingSeedPhraseIntroLegacy = Localization.tr("Localizable", "onboarding_seed_phrase_intro_legacy")
  /// For security reasons, taking screenshots of your seed phrase is disabled. The seed phrase is hidden to protect it from loss or unauthorized access.
  public static let onboardingSeedScreenshotAlert = Localization.tr("Localizable", "onboarding_seed_screenshot_alert")
  /// To check whether you’ve written down your seed phrase correctly, please enter the 2nd, 7th and 11th words
  public static let onboardingSeedUserValidationMessage = Localization.tr("Localizable", "onboarding_seed_user_validation_message")
  /// So, let’s check
  public static let onboardingSeedUserValidationTitle = Localization.tr("Localizable", "onboarding_seed_user_validation_title")
  /// To start the backup process, add up to two backup cards or rings.
  public static let onboardingSubtitleNoBackupCards = Localization.tr("Localizable", "onboarding_subtitle_no_backup_cards")
  /// You can add one more card or ring or finalize the backup process
  public static let onboardingSubtitleOneBackupCard = Localization.tr("Localizable", "onboarding_subtitle_one_backup_card")
  /// Prepare the backup card with number %@
  public static func onboardingSubtitleScanBackupCardFormat(_ p1: Any) -> String {
    return Localization.tr("Localizable", "onboarding_subtitle_scan_backup_card_format", String(describing: p1))
  }
  /// Scan the primary card or ring to start the backup process.
  public static let onboardingSubtitleScanPrimary = Localization.tr("Localizable", "onboarding_subtitle_scan_primary")
  /// Prepare the primary card with number %@
  public static func onboardingSubtitleScanPrimaryCardFormat(_ p1: Any) -> String {
    return Localization.tr("Localizable", "onboarding_subtitle_scan_primary_card_format", String(describing: p1))
  }
  /// Prepare the ring and press the scan button below
  public static let onboardingSubtitleScanRing = Localization.tr("Localizable", "onboarding_subtitle_scan_ring")
  /// Your wallet is configured and ready for use.
  public static let onboardingSubtitleSuccessTangemWalletOnboarding = Localization.tr("Localizable", "onboarding_subtitle_success_tangem_wallet_onboarding")
  /// Max number of devices added. Finalize the backup process.
  public static let onboardingSubtitleTwoBackupCards = Localization.tr("Localizable", "onboarding_subtitle_two_backup_cards")
  /// Activating wallet
  public static let onboardingTitle = Localization.tr("Localizable", "onboarding_title")
  /// Backup card
  public static let onboardingTitleBackupCard = Localization.tr("Localizable", "onboarding_title_backup_card")
  /// Backup ring
  public static let onboardingTitleBackupRing = Localization.tr("Localizable", "onboarding_title_backup_ring")
  /// No backup devices
  public static let onboardingTitleNoBackupCards = Localization.tr("Localizable", "onboarding_title_no_backup_cards")
  /// Notifications
  public static let onboardingTitleNotifications = Localization.tr("Localizable", "onboarding_title_notifications")
  /// One backup device added
  public static let onboardingTitleOneBackupCard = Localization.tr("Localizable", "onboarding_title_one_backup_card")
  /// Prepare your card or ring
  public static let onboardingTitleScanOriginCard = Localization.tr("Localizable", "onboarding_title_scan_origin_card")
  /// Two backup devices added
  public static let onboardingTitleTwoBackupCards = Localization.tr("Localizable", "onboarding_title_two_backup_cards")
  /// To get started, simply top up the wallet with more than %1$@
  public static func onboardingTopUpMinCreateAccountAmount(_ p1: Any) -> String {
    return Localization.tr("Localizable", "onboarding_top_up_min_create_account_amount", String(describing: p1))
  }
  /// The twinning process is partly complete. You can't exit it now.
  public static let onboardingTwinExitWarning = Localization.tr("Localizable", "onboarding_twin_exit_warning")
  /// If the process of creating the wallet gets interrupted in any way, you'll have to start over
  public static let onboardingTwinsInterruptWarning = Localization.tr("Localizable", "onboarding_twins_interrupt_warning")
  /// You can backup your keys up to two other blank Tangem Wallet cards or rings.
  public static let onboardingWalletInfoSubtitleFirst = Localization.tr("Localizable", "onboarding_wallet_info_subtitle_first")
  /// Access code can be restored with one of backup cards.
  public static let onboardingWalletInfoSubtitleFourth = Localization.tr("Localizable", "onboarding_wallet_info_subtitle_fourth")
  /// All the backup cards can be used as full-functional with the identical keys.
  public static let onboardingWalletInfoSubtitleSecond = Localization.tr("Localizable", "onboarding_wallet_info_subtitle_second")
  /// You will be able to set an access code to protect your wallets.
  public static let onboardingWalletInfoSubtitleThird = Localization.tr("Localizable", "onboarding_wallet_info_subtitle_third")
  /// Backup wallet
  public static let onboardingWalletInfoTitleFirst = Localization.tr("Localizable", "onboarding_wallet_info_title_first")
  /// Access code restore
  public static let onboardingWalletInfoTitleFourth = Localization.tr("Localizable", "onboarding_wallet_info_title_fourth")
  /// Identical cards
  public static let onboardingWalletInfoTitleSecond = Localization.tr("Localizable", "onboarding_wallet_info_title_second")
  /// Access code
  public static let onboardingWalletInfoTitleThird = Localization.tr("Localizable", "onboarding_wallet_info_title_third")
  /// You can only have one mobile wallet. Upgrade it to Tangem hardware wallet, or add a new hardware wallet.
  public static let onlyOneMobileWalletExplanation = Localization.tr("Localizable", "only_one_mobile_wallet_explanation")
  /// All offers
  public static let onrampAllOffersButtonTitle = Localization.tr("Localizable", "onramp_all_offers_button_title")
  /// Available with %@
  public static func onrampAvaiableWithPaymentMethods(_ p1: Any) -> String {
    return Localization.tr("Localizable", "onramp_avaiable_with_payment_methods", String(describing: p1))
  }
  /// Providers facilitate transactions
  public static let onrampChooseProviderTitleHint = Localization.tr("Localizable", "onramp_choose_provider_title_hint")
  /// Search by country
  public static let onrampCountrySearch = Localization.tr("Localizable", "onramp_country_search")
  /// Unavailable
  public static let onrampCountryUnavailable = Localization.tr("Localizable", "onramp_country_unavailable")
  /// Other currencies
  public static let onrampCurrencyOther = Localization.tr("Localizable", "onramp_currency_other")
  /// Popular Fiats
  public static let onrampCurrencyPopular = Localization.tr("Localizable", "onramp_currency_popular")
  /// Search by currency
  public static let onrampCurrencySearch = Localization.tr("Localizable", "onramp_currency_search")
  /// This transaction has already been processed. No further action is required.
  public static let onrampErrorTransactionAlreadyProcessed = Localization.tr("Localizable", "onramp_error_transaction_already_processed")
  /// Fetching best rates...
  public static let onrampFetchingBestRates = Localization.tr("Localizable", "onramp_fetching_best_rates")
  /// Instant
  public static let onrampInstantStatus = Localization.tr("Localizable", "onramp_instant_status")
  /// By using onramp functionality, you agree with provider’s %1$@ and %2$@
  public static func onrampLegal(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "onramp_legal", String(describing: p1), String(describing: p2))
  }
  /// Service is provided by an external provider.\nTangem is not responsible.
  public static let onrampLegalText = Localization.tr("Localizable", "onramp_legal_text")
  /// The purchase amount should be no more than %@
  public static func onrampMaxAmountRestriction(_ p1: Any) -> String {
    return Localization.tr("Localizable", "onramp_max_amount_restriction", String(describing: p1))
  }
  /// The amount to buy must be at least %@
  public static func onrampMinAmountRestriction(_ p1: Any) -> String {
    return Localization.tr("Localizable", "onramp_min_amount_restriction", String(describing: p1))
  }
  /// No available providers for this currency
  public static let onrampNoAvailableProviders = Localization.tr("Localizable", "onramp_no_available_providers")
  /// Quickest Processing
  public static let onrampOfferTypeFastet = Localization.tr("Localizable", "onramp_offer_type_fastet")
  /// Pay with
  public static let onrampPayWith = Localization.tr("Localizable", "onramp_pay_with")
  /// Payment method
  public static let onrampPaymentMethodSubtitle = Localization.tr("Localizable", "onramp_payment_method_subtitle")
  /// Available up to %@
  public static func onrampProviderMaxAmount(_ p1: Any) -> String {
    return Localization.tr("Localizable", "onramp_provider_max_amount", String(describing: p1))
  }
  /// Available from %@
  public static func onrampProviderMinAmount(_ p1: Any) -> String {
    return Localization.tr("Localizable", "onramp_provider_min_amount", String(describing: p1))
  }
  /// Plural format key: "%#@format@"
  public static func onrampProvidersCount(_ p1: Int) -> String {
    return Localization.tr("Localizable", "onramp_providers_count", p1)
  }
  /// Providers
  public static let onrampProvidersSubtitle = Localization.tr("Localizable", "onramp_providers_subtitle")
  /// Recently used
  public static let onrampRecentlyUsedTitle = Localization.tr("Localizable", "onramp_recently_used_title")
  /// Recommended
  public static let onrampRecommendedTitle = Localization.tr("Localizable", "onramp_recommended_title")
  /// You will be able to complete your transaction on the third-party provider, %@
  public static func onrampRedirectingToProviderSubtitle(_ p1: Any) -> String {
    return Localization.tr("Localizable", "onramp_redirecting_to_provider_subtitle", String(describing: p1))
  }
  /// Redirecting to %@...
  public static func onrampRedirectingToProviderTitle(_ p1: Any) -> String {
    return Localization.tr("Localizable", "onramp_redirecting_to_provider_title", String(describing: p1))
  }
  /// Our services are not available in this country
  public static let onrampResidencyBottomsheetCountryNotSupported = Localization.tr("Localizable", "onramp_residency_bottomsheet_country_not_supported")
  /// Your residence has been identified as
  public static let onrampResidencyBottomsheetTitle = Localization.tr("Localizable", "onramp_residency_bottomsheet_title")
  /// Residence
  public static let onrampSettingsResidence = Localization.tr("Localizable", "onramp_settings_residence")
  /// Please select the correct country to ensure accurate payment options and services.
  public static let onrampSettingsResidenceDescription = Localization.tr("Localizable", "onramp_settings_residence_description")
  /// Settings
  public static let onrampSettingsTitle = Localization.tr("Localizable", "onramp_settings_title")
  /// You can close this screen and check the transaction status on the token details screen.
  public static let onrampStatusesViewFooter = Localization.tr("Localizable", "onramp_statuses_view_footer")
  /// Plural format key: "%#@format@"
  public static func onrampTimingDays(_ p1: Int) -> String {
    return Localization.tr("Localizable", "onramp_timing_days", p1)
  }
  /// %@ min
  public static func onrampTimingMinutes(_ p1: Any) -> String {
    return Localization.tr("Localizable", "onramp_timing_minutes", String(describing: p1))
  }
  /// Available from
  public static let onrampTitleAvailableFrom = Localization.tr("Localizable", "onramp_title_available_from")
  /// Available up to
  public static let onrampTitleAvailableUpTo = Localization.tr("Localizable", "onramp_title_available_up_to")
  /// You get
  public static let onrampTitleYouGet = Localization.tr("Localizable", "onramp_title_you_get")
  /// Service is provided by an external provider. \nTangem is not responsible.
  public static let onrampTosExternalProviders = Localization.tr("Localizable", "onramp_tos_external_providers")
  /// You can close this screen and check the transaction status on the token details screen.
  public static let onrampTransactionStatusFooterText = Localization.tr("Localizable", "onramp_transaction_status_footer_text")
  /// Up to
  public static let onrampUpToRate = Localization.tr("Localizable", "onramp_up_to_rate")
  /// Via
  public static let onrampVia = Localization.tr("Localizable", "onramp_via")
  /// via %@
  public static func onrampViaProvider(_ p1: Any) -> String {
    return Localization.tr("Localizable", "onramp_via_provider", String(describing: p1))
  }
  /// You will pay
  public static let onrampYouWillPayTitle = Localization.tr("Localizable", "onramp_you_will_pay_title")
  /// Group
  public static let organizeTokensGroup = Localization.tr("Localizable", "organize_tokens_group")
  /// By balance
  public static let organizeTokensSortByBalance = Localization.tr("Localizable", "organize_tokens_sort_by_balance")
  /// Organize tokens
  public static let organizeTokensTitle = Localization.tr("Localizable", "organize_tokens_title")
  /// Ungroup
  public static let organizeTokensUngroup = Localization.tr("Localizable", "organize_tokens_ungroup")
  /// %@ support
  public static func providerNameSupport(_ p1: Any) -> String {
    return Localization.tr("Localizable", "provider_name_support", String(describing: p1))
  }
  /// More info
  public static let pushNotificationsMoreInfo = Localization.tr("Localizable", "push_notifications_more_info")
  /// You can enable Notifications for Tangem in Settings.
  public static let pushNotificationsPermissionAlertDescription = Localization.tr("Localizable", "push_notifications_permission_alert_description")
  /// Enable Later
  public static let pushNotificationsPermissionAlertNegativeButton = Localization.tr("Localizable", "push_notifications_permission_alert_negative_button")
  /// Settings
  public static let pushNotificationsPermissionAlertPositiveButton = Localization.tr("Localizable", "push_notifications_permission_alert_positive_button")
  /// Enable Notifications
  public static let pushNotificationsPermissionAlertTitle = Localization.tr("Localizable", "push_notifications_permission_alert_title")
  /// Receive alerts for incoming transactions on supported networks
  public static let pushTransactionsNotificationsDescription = Localization.tr("Localizable", "push_transactions_notifications_description")
  /// Transaction Notifications
  public static let pushTransactionsNotificationsTitle = Localization.tr("Localizable", "push_transactions_notifications_title")
  /// Select from the gallery
  public static let qrScannerCameraDeniedGalleryButton = Localization.tr("Localizable", "qr_scanner_camera_denied_gallery_button")
  /// Settings
  public static let qrScannerCameraDeniedSettingsButton = Localization.tr("Localizable", "qr_scanner_camera_denied_settings_button")
  /// You have not given access to your camera
  public static let qrScannerCameraDeniedText = Localization.tr("Localizable", "qr_scanner_camera_denied_text")
  /// Camera access denied
  public static let qrScannerCameraDeniedTitle = Localization.tr("Localizable", "qr_scanner_camera_denied_title")
  /// No memo required
  public static let receiveBottomSheetNoMemoRequiredMessage = Localization.tr("Localizable", "receive_bottom_sheet_no_memo_required_message")
  /// %1$@ (%2$@) on %3$@ network
  public static func receiveBottomSheetWarningMessage(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return Localization.tr("Localizable", "receive_bottom_sheet_warning_message", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// %1$@ on %2$@ network
  public static func receiveBottomSheetWarningMessageCompact(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "receive_bottom_sheet_warning_message_compact", String(describing: p1), String(describing: p2))
  }
  /// Sending any other currency will result in its irreversible loss.
  public static let receiveBottomSheetWarningMessageDescription = Localization.tr("Localizable", "receive_bottom_sheet_warning_message_description")
  /// Send only %@ to this address.
  public static func receiveBottomSheetWarningMessageTitle(_ p1: Any) -> String {
    return Localization.tr("Localizable", "receive_bottom_sheet_warning_message_title", String(describing: p1))
  }
  /// Send only %1$@ on the %2$@ network
  public static func receiveBottomSheetWarningTitle(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "receive_bottom_sheet_warning_title", String(describing: p1), String(describing: p2))
  }
  /// Transfer funds from any wallet or exchange
  public static let receiveTokenDescription = Localization.tr("Localizable", "receive_token_description")
  /// Address for rewards
  public static let referralAddressForRewards = Localization.tr("Localizable", "referral_address_for_rewards")
  /// Participate
  public static let referralButtonParticipate = Localization.tr("Localizable", "referral_button_participate")
  /// Failed to load the information about the referral program. Please try again later.
  public static let referralErrorFailedToLoadInfo = Localization.tr("Localizable", "referral_error_failed_to_load_info")
  /// Failed to load the information about the referral program. Error code: %@. Please try again later.
  public static func referralErrorFailedToLoadInfoWithReason(_ p1: Any) -> String {
    return Localization.tr("Localizable", "referral_error_failed_to_load_info_with_reason", String(describing: p1))
  }
  /// Your participation request could not be processed. Error code: %@. Please try again later. If the problem persists — feel free to contact our support.
  public static func referralErrorFailedToParticipate(_ p1: Any) -> String {
    return Localization.tr("Localizable", "referral_error_failed_to_participate", String(describing: p1))
  }
  /// Upcoming payments
  public static let referralExpectedAwards = Localization.tr("Localizable", "referral_expected_awards")
  /// Your friends bought
  public static let referralFriendsBoughtTitle = Localization.tr("Localizable", "referral_friends_bought_title")
  /// Less
  public static let referralLess = Localization.tr("Localizable", "referral_less")
  /// More
  public static let referralMore = Localization.tr("Localizable", "referral_more")
  /// No upcoming payments
  public static let referralNoExpectedAwards = Localization.tr("Localizable", "referral_no_expected_awards")
  /// Plural format key: "%#@format@"
  public static func referralNumberOfWallets(_ p1: Int) -> String {
    return Localization.tr("Localizable", "referral_number_of_wallets", p1)
  }
  /// Will get ^^%1$@^^ for each wallet bought by your friend on your %2$@ network address %3$@ ^^30 days after^^ that
  public static func referralPointCurrenciesDescription(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return Localization.tr("Localizable", "referral_point_currencies_description", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// You
  public static let referralPointCurrenciesTitle = Localization.tr("Localizable", "referral_point_currencies_title")
  /// Will get a
  public static let referralPointDiscountDescriptionPrefix = Localization.tr("Localizable", "referral_point_discount_description_prefix")
  /// when buying a wallet on tangem.com
  public static let referralPointDiscountDescriptionSuffix = Localization.tr("Localizable", "referral_point_discount_description_suffix")
  /// %@ discount
  public static func referralPointDiscountDescriptionValue(_ p1: Any) -> String {
    return Localization.tr("Localizable", "referral_point_discount_description_value", String(describing: p1))
  }
  /// Your friend
  public static let referralPointDiscountTitle = Localization.tr("Localizable", "referral_point_discount_title")
  /// Personal code copied!
  public static let referralPromoCodeCopied = Localization.tr("Localizable", "referral_promo_code_copied")
  /// Your personal code
  public static let referralPromoCodeTitle = Localization.tr("Localizable", "referral_promo_code_title")
  /// Buy Tangem Wallet with discount!\n%@
  public static func referralShareLink(_ p1: Any) -> String {
    return Localization.tr("Localizable", "referral_share_link", String(describing: p1))
  }
  /// Refer your friends to Tangem
  public static let referralTitle = Localization.tr("Localizable", "referral_title")
  /// You've accepted
  public static let referralTosEnroledPrefix = Localization.tr("Localizable", "referral_tos_enroled_prefix")
  /// By tapping this button you accept
  public static let referralTosNotEnroledPrefix = Localization.tr("Localizable", "referral_tos_not_enroled_prefix")
  /// of the referral program
  public static let referralTosSuffix = Localization.tr("Localizable", "referral_tos_suffix")
  /// Plural format key: "%#@format@"
  public static func referralWalletsPurchasedCount(_ p1: Int) -> String {
    return Localization.tr("Localizable", "referral_wallets_purchased_count", p1)
  }
  /// Reset the card
  public static let resetCardToFactoryButtonTitle = Localization.tr("Localizable", "reset_card_to_factory_button_title")
  /// I understand that after performing this action, I will no longer have access to the current wallet
  public static let resetCardToFactoryCondition1 = Localization.tr("Localizable", "reset_card_to_factory_condition_1")
  /// I realize that I can't use this card to recover my access code on the other cards of the current wallet
  public static let resetCardToFactoryCondition2 = Localization.tr("Localizable", "reset_card_to_factory_condition_2")
  /// I understand that I will completely lose access to my Tangem Pay Card and all funds on it without the possibility of recovery
  public static let resetCardToFactoryCondition3 = Localization.tr("Localizable", "reset_card_to_factory_condition_3")
  /// A factory reset completely erases the wallet from the selected card or ring. You will not be able to restore the current wallet or use this card or ring to recover the access code.
  public static let resetCardWithBackupToFactoryMessage = Localization.tr("Localizable", "reset_card_with_backup_to_factory_message")
  /// A factory reset completely erases the wallet from the selected card or ring and removes it from the app. You will not be able to restore the current wallet.
  public static let resetCardWithoutBackupToFactoryMessage = Localization.tr("Localizable", "reset_card_without_backup_to_factory_message")
  /// All Tangem devices have been reset.
  public static let resetCardsDialogCompleteDescription = Localization.tr("Localizable", "reset_cards_dialog_complete_description")
  /// Something went wrong with the activation process. Please reset the cards one by one.
  public static let resetCardsDialogFirstDescription = Localization.tr("Localizable", "reset_cards_dialog_first_description")
  /// Card verification failed
  public static let resetCardsDialogFirstTitle = Localization.tr("Localizable", "reset_cards_dialog_first_title")
  /// Please reset the next device to continue
  public static let resetCardsDialogNextDeviceDescription = Localization.tr("Localizable", "reset_cards_dialog_next_device_description")
  /// Log into the app and check your balance without scanning the card or ring
  public static let saveUserWalletAgreementAccessDescription = Localization.tr("Localizable", "save_user_wallet_agreement_access_description")
  /// Access the app
  public static let saveUserWalletAgreementAccessTitle = Localization.tr("Localizable", "save_user_wallet_agreement_access_title")
  /// Allow to use %@
  public static func saveUserWalletAgreementAllow(_ p1: Any) -> String {
    return Localization.tr("Localizable", "save_user_wallet_agreement_allow", String(describing: p1))
  }
  /// %@ will be requested instead of the access code for interactions with your wallet
  public static func saveUserWalletAgreementCodeDescription(_ p1: Any) -> String {
    return Localization.tr("Localizable", "save_user_wallet_agreement_code_description", String(describing: p1))
  }
  /// Access code
  public static let saveUserWalletAgreementCodeTitle = Localization.tr("Localizable", "save_user_wallet_agreement_code_title")
  /// Don't allow
  public static let saveUserWalletAgreementDontAllow = Localization.tr("Localizable", "save_user_wallet_agreement_dont_allow")
  /// Would you like to use %@?
  public static func saveUserWalletAgreementHeader(_ p1: Any) -> String {
    return Localization.tr("Localizable", "save_user_wallet_agreement_header", String(describing: p1))
  }
  /// Note that making a transaction with your funds will still require your card or ring
  public static let saveUserWalletAgreementNotice = Localization.tr("Localizable", "save_user_wallet_agreement_notice")
  /// Scan card or ring
  public static let scanCardSettingsButton = Localization.tr("Localizable", "scan_card_settings_button")
  /// Scan the card or ring to change its settings. The changes will impact only the card or ring you've scanned and will not affect other devices tied to your wallet.
  public static let scanCardSettingsMessage = Localization.tr("Localizable", "scan_card_settings_message")
  /// Get your Tangem ready!
  public static let scanCardSettingsTitle = Localization.tr("Localizable", "scan_card_settings_title")
  /// Security Alert
  public static let securityAlertTitle = Localization.tr("Localizable", "security_alert_title")
  /// No, I did not
  public static let seedWarningNo = Localization.tr("Localizable", "seed_warning_no")
  /// Yes, guide me
  public static let seedWarningYes = Localization.tr("Localizable", "seed_warning_yes")
  /// You don’t have enough funds in your balance to sell cryptocurrency. Please deposit the desired asset to proceed.
  public static let sellingInsufficientBalanceAlertMessage = Localization.tr("Localizable", "selling_insufficient_balance_alert_message")
  /// Insufficient Balance
  public static let sellingInsufficientBalanceAlertTitle = Localization.tr("Localizable", "selling_insufficient_balance_alert_title")
  /// Selling cryptocurrency is unavailable in your region at the moment. We’re actively working to bring this option to you soon—stay tuned!
  public static let sellingRegionalRestrictionAlertMessage = Localization.tr("Localizable", "selling_regional_restriction_alert_message")
  /// Regional Restriction
  public static let sellingRegionalRestrictionAlertTitle = Localization.tr("Localizable", "selling_regional_restriction_alert_title")
  /// Already included in the entered address
  public static let sendAdditionalFieldAlreadyIncluded = Localization.tr("Localizable", "send_additional_field_already_included")
  /// Your commission amount is %@ times higher than the recommended amount. Please review and adjust your custom settings.
  public static func sendAlertFeeTooHighText(_ p1: Any) -> String {
    return Localization.tr("Localizable", "send_alert_fee_too_high_text", String(describing: p1))
  }
  /// You specified a commission below the recommended amount, which could cause a delay in your transaction. Continue?
  public static let sendAlertFeeTooLowText = Localization.tr("Localizable", "send_alert_fee_too_low_text")
  /// Reason: %1$@\nCode: %2$@
  public static func sendAlertTransactionFailedText(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "send_alert_transaction_failed_text", String(describing: p1), String(describing: p2))
  }
  /// The transaction is not completed
  public static let sendAlertTransactionFailedTitle = Localization.tr("Localizable", "send_alert_transaction_failed_title")
  /// Swap to another token or network
  public static let sendAmountConvertToAnotherToken = Localization.tr("Localizable", "send_amount_convert_to_another_token")
  /// Will be sent to recipient
  public static let sendAmountReceiveTokenSubtitle = Localization.tr("Localizable", "send_amount_receive_token_subtitle")
  /// You can set your transaction fee by adjusting the value in the Satoshi per vByte field.
  public static let sendBitcoinCustomFeeFooter = Localization.tr("Localizable", "send_bitcoin_custom_fee_footer")
  /// The fee that will be charged for your transaction. You can set your own value.
  public static let sendCustomAmountFeeFooter = Localization.tr("Localizable", "send_custom_amount_fee_footer")
  /// Max fee
  public static let sendCustomEvmMaxFee = Localization.tr("Localizable", "send_custom_evm_max_fee")
  /// This is the cost you are willing to pay for each unit of gas. The higher the gas price, the faster your transaction will be processed. (Priority fee included)
  public static let sendCustomEvmMaxFeeFooter = Localization.tr("Localizable", "send_custom_evm_max_fee_footer")
  /// Priority fee
  public static let sendCustomEvmPriorityFee = Localization.tr("Localizable", "send_custom_evm_priority_fee")
  /// The fee that a user can pay to miners or validators to expedite the inclusion of their transaction in a block.
  public static let sendCustomEvmPriorityFeeFooter = Localization.tr("Localizable", "send_custom_evm_priority_fee_footer")
  /// %1$@, %2$@
  public static func sendDateFormat(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "send_date_format", String(describing: p1), String(describing: p2))
  }
  /// Destination Tag
  public static let sendDestinationTagField = Localization.tr("Localizable", "send_destination_tag_field")
  /// Are you sure you want to close the send screen?
  public static let sendDismissMessage = Localization.tr("Localizable", "send_dismiss_message")
  /// Enter address
  public static let sendEnterAddressField = Localization.tr("Localizable", "send_enter_address_field")
  /// ENS name or address
  public static let sendEnterAddressFieldEns = Localization.tr("Localizable", "send_enter_address_field_ens")
  /// Address is the same as wallet address
  public static let sendErrorAddressSameAsWallet = Localization.tr("Localizable", "send_error_address_same_as_wallet")
  /// Change is too small
  public static let sendErrorDustChange = Localization.tr("Localizable", "send_error_dust_change")
  /// Target account is not created. Amount to send should be %@ + fee or more
  public static func sendErrorNoTargetAccount(_ p1: Any) -> String {
    return Localization.tr("Localizable", "send_error_no_target_account", String(describing: p1))
  }
  /// Unknown error
  public static let sendErrorUnknown = Localization.tr("Localizable", "send_error_unknown")
  /// Memo
  public static let sendExtrasHintMemo = Localization.tr("Localizable", "send_extras_hint_memo")
  /// Check your network connection
  public static let sendFeeUnreachableErrorText = Localization.tr("Localizable", "send_fee_unreachable_error_text")
  /// Network fee info unreachable
  public static let sendFeeUnreachableErrorTitle = Localization.tr("Localizable", "send_fee_unreachable_error_title")
  /// You send
  public static let sendFromTitle = Localization.tr("Localizable", "send_from_title")
  /// From **%@**
  public static func sendFromWallet(_ p1: Any) -> String {
    return Localization.tr("Localizable", "send_from_wallet", String(describing: p1))
  }
  /// From %@
  public static func sendFromWalletName(_ p1: Any) -> String {
    return Localization.tr("Localizable", "send_from_wallet_name", String(describing: p1))
  }
  /// Gas limit
  public static let sendGasLimit = Localization.tr("Localizable", "send_gas_limit")
  /// This is the maximum amount of gas that will be spent to complete a transaction or contract. A gas limit prevents unexpected or unlimited charges when executing a transaction.
  public static let sendGasLimitFooter = Localization.tr("Localizable", "send_gas_limit_footer")
  /// Gas price
  public static let sendGasPrice = Localization.tr("Localizable", "send_gas_price")
  /// This is the cost you are willing to pay for each unit of gas. The higher the gas price, the faster your transaction will be processed.
  public static let sendGasPriceFooter = Localization.tr("Localizable", "send_gas_price_footer")
  /// Max
  public static let sendMaxAmount = Localization.tr("Localizable", "send_max_amount")
  /// Maximum amount
  public static let sendMaxAmountLabel = Localization.tr("Localizable", "send_max_amount_label")
  /// Fee up to
  public static let sendMaxFee = Localization.tr("Localizable", "send_max_fee")
  /// Memo: %@
  public static func sendMemo(_ p1: Any) -> String {
    return Localization.tr("Localizable", "send_memo", String(describing: p1))
  }
  /// Invalid Memo
  public static let sendMemoDestinationTagError = Localization.tr("Localizable", "send_memo_destination_tag_error")
  /// Network fee coverage
  public static let sendNetworkFeeWarningTitle = Localization.tr("Localizable", "send_network_fee_warning_title")
  /// Nonce
  public static let sendNonce = Localization.tr("Localizable", "send_nonce")
  /// Unique number for each transaction. Use it to resend or cancel a pending transaction.
  public static let sendNonceFooter = Localization.tr("Localizable", "send_nonce_footer")
  /// Enter nonce…
  public static let sendNonceHint = Localization.tr("Localizable", "send_nonce_hint")
  /// Insufficient funds for the transfer, as the total of the fee and transfer amount exceeds the existing balance
  public static let sendNotificationExceedBalanceText = Localization.tr("Localizable", "send_notification_exceed_balance_text")
  /// Total exceeds balance
  public static let sendNotificationExceedBalanceTitle = Localization.tr("Localizable", "send_notification_exceed_balance_title")
  /// A balance of at least %@ is required to keep your account on the blockchain to prevent security risks. This amount will remain in your balance and cannot be withdrawn.
  public static func sendNotificationExistentialDepositText(_ p1: Any) -> String {
    return Localization.tr("Localizable", "send_notification_existential_deposit_text", String(describing: p1))
  }
  /// Existential deposit
  public static let sendNotificationExistentialDepositTitle = Localization.tr("Localizable", "send_notification_existential_deposit_title")
  /// Your commission amount is %@ times higher than the recommended amount. Please review and adjust your custom settings.
  public static func sendNotificationFeeTooHighText(_ p1: Any) -> String {
    return Localization.tr("Localizable", "send_notification_fee_too_high_text", String(describing: p1))
  }
  /// Custom fee is high
  public static let sendNotificationFeeTooHighTitle = Localization.tr("Localizable", "send_notification_fee_too_high_title")
  /// Due to the peculiarities of the %1$@ network, the fee for transferring the entire balance is higher. To reduce the commission, you can leave %2$@.
  public static func sendNotificationHighFeeText(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "send_notification_high_fee_text", String(describing: p1), String(describing: p2))
  }
  /// The fee is higher
  public static let sendNotificationHighFeeTitle = Localization.tr("Localizable", "send_notification_high_fee_title")
  /// The recipient account is not activated. The minimum transfer amount must be equal to or greater than the rent-exempt balance: %1$@.
  public static func sendNotificationInvalidAmountRentDestination(_ p1: Any) -> String {
    return Localization.tr("Localizable", "send_notification_invalid_amount_rent_destination", String(describing: p1))
  }
  /// Your account balance cannot be lower than the rent fee. Please maintain at least %1$@ on your account or withdraw all funds.
  public static func sendNotificationInvalidAmountRentFee(_ p1: Any) -> String {
    return Localization.tr("Localizable", "send_notification_invalid_amount_rent_fee", String(describing: p1))
  }
  /// The included commission exceeds the transfer amount, leading to a negative value
  public static let sendNotificationInvalidAmountText = Localization.tr("Localizable", "send_notification_invalid_amount_text")
  /// Invalid amount
  public static let sendNotificationInvalidAmountTitle = Localization.tr("Localizable", "send_notification_invalid_amount_title")
  /// The minimum sending amount is %1$@. Please ensure that the remaining balance after sending will not be less than %2$@.
  public static func sendNotificationInvalidMinimumAmountText(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "send_notification_invalid_minimum_amount_text", String(describing: p1), String(describing: p2))
  }
  /// Target account is not created. Please change the amount to send.
  public static let sendNotificationInvalidReserveAmountText = Localization.tr("Localizable", "send_notification_invalid_reserve_amount_text")
  /// The amount to send must be at least %@
  public static func sendNotificationInvalidReserveAmountTitle(_ p1: Any) -> String {
    return Localization.tr("Localizable", "send_notification_invalid_reserve_amount_title", String(describing: p1))
  }
  /// Leave %@
  public static func sendNotificationLeaveButton(_ p1: Any) -> String {
    return Localization.tr("Localizable", "send_notification_leave_button", String(describing: p1))
  }
  /// Reduce by %@
  public static func sendNotificationReduceBy(_ p1: Any) -> String {
    return Localization.tr("Localizable", "send_notification_reduce_by", String(describing: p1))
  }
  /// Reduce to %@
  public static func sendNotificationReduceTo(_ p1: Any) -> String {
    return Localization.tr("Localizable", "send_notification_reduce_to", String(describing: p1))
  }
  /// Kindly be aware that your transaction may experience delays under specific fee settings
  public static let sendNotificationTransactionDelayText = Localization.tr("Localizable", "send_notification_transaction_delay_text")
  /// Transaction delays are possible
  public static let sendNotificationTransactionDelayTitle = Localization.tr("Localizable", "send_notification_transaction_delay_title")
  /// Due to %1$@ limitations only %2$@ UTXOs can fit in a single transaction. This means you can only send %3$@ or less. You need to reduce the amount.
  public static func sendNotificationTransactionLimitText(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return Localization.tr("Localizable", "send_notification_transaction_limit_text", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// Transaction limitation
  public static let sendNotificationTransactionLimitTitle = Localization.tr("Localizable", "send_notification_transaction_limit_title")
  /// Optional
  public static let sendOptionalField = Localization.tr("Localizable", "send_optional_field")
  /// Please align your QR code with the square to scan it. Ensure you scan %@ network address.
  public static func sendQrcodeScanInfo(_ p1: Any) -> String {
    return Localization.tr("Localizable", "send_qrcode_scan_info", String(describing: p1))
  }
  /// Recent
  public static let sendRecentTransactions = Localization.tr("Localizable", "send_recent_transactions")
  /// Recipient
  public static let sendRecipient = Localization.tr("Localizable", "send_recipient")
  /// Not a valid address
  public static let sendRecipientAddressError = Localization.tr("Localizable", "send_recipient_address_error")
  /// Ensure the recipient's address is on **the %@ network** to avoid losing your funds
  public static func sendRecipientAddressFooter(_ p1: Any) -> String {
    return Localization.tr("Localizable", "send_recipient_address_footer", String(describing: p1))
  }
  /// A Memo/Destination Tag is a unique ID for differentiating transactions sent to the same recipient on the same network.\n**Caution: Omitting a memo may lead to misplaced funds**
  public static let sendRecipientMemoFooter = Localization.tr("Localizable", "send_recipient_memo_footer")
  /// Caution: Missing a memo may lead to fund loss.
  public static let sendRecipientMemoFooterV2Highlighted = Localization.tr("Localizable", "send_recipient_memo_footer_v2_highlighted")
  /// My wallets
  public static let sendRecipientWalletsTitle = Localization.tr("Localizable", "send_recipient_wallets_title")
  /// A way of measuring Bitcoin transaction fees. It indicates the number of the smallest Bitcoin unit (Satoshi) for each virtual byte in a transaction. The higher the number, the faster the transaction will be processed by miners.
  public static let sendSatoshiPerByteText = Localization.tr("Localizable", "send_satoshi_per_byte_text")
  /// Satoshi / vByte
  public static let sendSatoshiPerByteTitle = Localization.tr("Localizable", "send_satoshi_per_byte_title")
  /// Sending...
  public static let sendSending = Localization.tr("Localizable", "send_sending")
  /// Tap any field to change it
  public static let sendSummaryTapHint = Localization.tr("Localizable", "send_summary_tap_hint")
  /// Send %@
  public static func sendSummaryTitle(_ p1: Any) -> String {
    return Localization.tr("Localizable", "send_summary_title", String(describing: p1))
  }
  /// You are sending **%1$@** including a network fee of %2$@.
  public static func sendSummaryTransactionDescription(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "send_summary_transaction_description", String(describing: p1), String(describing: p2))
  }
  /// You are sending **%1$@** and %2$@
  public static func sendSummaryTransactionDescriptionNoFiatFee(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "send_summary_transaction_description_no_fiat_fee", String(describing: p1), String(describing: p2))
  }
  /// You are sending **%1$@**
  public static func sendSummaryTransactionDescriptionPrefix(_ p1: Any) -> String {
    return Localization.tr("Localizable", "send_summary_transaction_description_prefix", String(describing: p1))
  }
  /// network fee will be covered by using %1$@ energy
  public static func sendSummaryTransactionDescriptionSuffixFeeCovered(_ p1: Any) -> String {
    return Localization.tr("Localizable", "send_summary_transaction_description_suffix_fee_covered", String(describing: p1))
  }
  /// network fee will be reduced by spending %1$@ energy
  public static func sendSummaryTransactionDescriptionSuffixFeeReduced(_ p1: Any) -> String {
    return Localization.tr("Localizable", "send_summary_transaction_description_suffix_fee_reduced", String(describing: p1))
  }
  /// including a network fee of %1$@
  public static func sendSummaryTransactionDescriptionSuffixIncluding(_ p1: Any) -> String {
    return Localization.tr("Localizable", "send_summary_transaction_description_suffix_including", String(describing: p1))
  }
  /// To address
  public static let sendToAddress = Localization.tr("Localizable", "send_to_address")
  /// Transaction has been successfully signed and sent to the blockchain node. Wallet balance will be updated in a while
  public static let sendTransactionSuccess = Localization.tr("Localizable", "send_transaction_success")
  /// %1$@ is an asset in the Tron network. To calculate the fee and make a transaction you need to deposit some Tron (TRX) in your account.
  public static func sendTronAccountActivationError(_ p1: Any) -> String {
    return Localization.tr("Localizable", "send_tron_account_activation_error", String(describing: p1))
  }
  /// A destination tag (memo) is required to complete this transaction for the specified address.
  public static let sendValidationDestinationTagRequiredDescription = Localization.tr("Localizable", "send_validation_destination_tag_required_description")
  /// Destination Tag Required
  public static let sendValidationDestinationTagRequiredTitle = Localization.tr("Localizable", "send_validation_destination_tag_required_title")
  /// Are you sure you want to change the receiving token? This will reset your previously entered data.
  public static let sendWithSwapChangeTokenAlertMessage = Localization.tr("Localizable", "send_with_swap_change_token_alert_message")
  /// Changing token
  public static let sendWithSwapChangeTokenAlertTitle = Localization.tr("Localizable", "send_with_swap_change_token_alert_title")
  /// Swap and send
  public static let sendWithSwapConfirmTitle = Localization.tr("Localizable", "send_with_swap_confirm_title")
  /// Proceed with swap? This will clear your previous data.
  public static let sendWithSwapConvertTokenAlertMessage = Localization.tr("Localizable", "send_with_swap_convert_token_alert_message")
  /// Confirm Conversion
  public static let sendWithSwapConvertTokenAlertTitle = Localization.tr("Localizable", "send_with_swap_convert_token_alert_title")
  /// Sending any other currency will result in its irreversible loss.
  public static let sendWithSwapCorrectRecipientNetworkNotificationMessage = Localization.tr("Localizable", "send_with_swap_correct_recipient_network_notification_message")
  /// Select the correct recipient network
  public static let sendWithSwapCorrectRecipientNetworkNotificationTitle = Localization.tr("Localizable", "send_with_swap_correct_recipient_network_notification_title")
  /// Choose any token to receive. Your recipient gets exactly what you selected—seamlessly.
  public static let sendWithSwapNotificationText = Localization.tr("Localizable", "send_with_swap_notification_text")
  /// Recipient will receive
  public static let sendWithSwapRecipientAmountSuccessTitle = Localization.tr("Localizable", "send_with_swap_recipient_amount_success_title")
  /// To recipient
  public static let sendWithSwapRecipientAmountText = Localization.tr("Localizable", "send_with_swap_recipient_amount_text")
  /// Amount to receive
  public static let sendWithSwapRecipientAmountTitle = Localization.tr("Localizable", "send_with_swap_recipient_amount_title")
  /// Recipient gets %@
  public static func sendWithSwapRecipientGetAmount(_ p1: Any) -> String {
    return Localization.tr("Localizable", "send_with_swap_recipient_get_amount", String(describing: p1))
  }
  /// Are you sure you want to cancel the conversion? Your previous data will be cleared.
  public static let sendWithSwapRemoveConvertAlertMessage = Localization.tr("Localizable", "send_with_swap_remove_convert_alert_message")
  /// Remove Conversion
  public static let sendWithSwapRemoveConvertAlertTitle = Localization.tr("Localizable", "send_with_swap_remove_convert_alert_title")
  /// Send with swap
  public static let sendWithSwapTitle = Localization.tr("Localizable", "send_with_swap_title")
  /// Transaction sent
  public static let sentTransactionSentTitle = Localization.tr("Localizable", "sent_transaction_sent_title")
  /// Prepare to scan card or ring you want to set up.
  public static let settingsCardSettingsFooter = Localization.tr("Localizable", "settings_card_settings_footer")
  /// Forget wallet
  public static let settingsForgetWallet = Localization.tr("Localizable", "settings_forget_wallet")
  /// This will remove the wallet from the application. The wallet itself can be added again.
  public static let settingsForgetWalletFooter = Localization.tr("Localizable", "settings_forget_wallet_footer")
  /// Simple to use
  public static let settingsUpgradeBannerAdvantageFeatureTitle = Localization.tr("Localizable", "settings_upgrade_banner_advantage_feature_title")
  /// Keeps your crypto safe and offline. Slim as a credit card, safer than a bank vault.
  public static let settingsUpgradeBannerDescription = Localization.tr("Localizable", "settings_upgrade_banner_description")
  /// No seed phrase
  public static let settingsUpgradeBannerSeedPhraseFeatureTitle = Localization.tr("Localizable", "settings_upgrade_banner_seed_phrase_feature_title")
  /// Best in class hardware wallet
  public static let settingsUpgradeBannerSuperiorityFeatureTitle = Localization.tr("Localizable", "settings_upgrade_banner_superiority_feature_title")
  /// Tangem Cold Wallet
  public static let settingsUpgradeBannerTitle = Localization.tr("Localizable", "settings_upgrade_banner_title")
  /// Name
  public static let settingsWalletNameTitle = Localization.tr("Localizable", "settings_wallet_name_title")
  /// Put your token to work
  public static let stakeTokenDescription = Localization.tr("Localizable", "stake_token_description")
  /// A network fee is a small payment required to process and confirm your transaction on the blockchain.
  public static let stakingAccountInitializationFooter = Localization.tr("Localizable", "staking_account_initialization_footer")
  /// To begin staking, your TON account must be activated with a transaction of 1 TON. The funds stay in your account because this step only activates it for staking.
  public static let stakingAccountInitializationMessage = Localization.tr("Localizable", "staking_account_initialization_message")
  /// Account activation
  public static let stakingAccountInitializationTitle = Localization.tr("Localizable", "staking_account_initialization_title")
  /// Active
  public static let stakingActive = Localization.tr("Localizable", "staking_active")
  /// To unstake your assets, tap the block above
  public static let stakingActiveFooter = Localization.tr("Localizable", "staking_active_footer")
  /// The network fee has changed. Please review the new amount before proceeding.
  public static let stakingAlertNetworkFeeUpdatedMessage = Localization.tr("Localizable", "staking_alert_network_fee_updated_message")
  /// Network fee updated
  public static let stakingAlertNetworkFeeUpdatedTitle = Localization.tr("Localizable", "staking_alert_network_fee_updated_title")
  /// The amount to stake must be at least %@
  public static func stakingAmountRequirementError(_ p1: Any) -> String {
    return Localization.tr("Localizable", "staking_amount_requirement_error", String(describing: p1))
  }
  /// Staking amount will be rounded to %1$@ TRX due to network rules.
  public static func stakingAmountTronIntegerError(_ p1: Any) -> String {
    return Localization.tr("Localizable", "staking_amount_tron_integer_error", String(describing: p1))
  }
  /// Unstaking amount will be rounded to %1$@ TRX due to network rules.
  public static func stakingAmountTronIntegerErrorUnstaking(_ p1: Any) -> String {
    return Localization.tr("Localizable", "staking_amount_tron_integer_error_unstaking", String(describing: p1))
  }
  /// APR %1$@%%
  public static func stakingAprEarnBadge(_ p1: Any) -> String {
    return Localization.tr("Localizable", "staking_apr_earn_badge", String(describing: p1))
  }
  /// Your staking rewards will start after 5 epochs (~25 days) while your delegation is registered and counted by the network.
  public static let stakingCardanoDetailsRewardsInfoText = Localization.tr("Localizable", "staking_cardano_details_rewards_info_text")
  /// Claim unstaked
  public static let stakingClaimUnstaked = Localization.tr("Localizable", "staking_claim_unstaked")
  /// Stake account fee
  public static let stakingDetailsAccountFee = Localization.tr("Localizable", "staking_details_account_fee")
  /// A staking account is a special account where staked SOL tokens are stored. It is created when you delegate your tokens to a validator to participate in transaction validation and receive rewards. A small fee is charged for creating the staking account, which is returned after the staking is completed.
  public static let stakingDetailsAccountFeeInfo = Localization.tr("Localizable", "staking_details_account_fee_info")
  /// Annual percentage rate
  public static let stakingDetailsAnnualPercentageRate = Localization.tr("Localizable", "staking_details_annual_percentage_rate")
  /// APR: Shows the interest rate you could earn in a year without compounding. Your earned interest is not added to your balance, so your earnings don’t grow on themselves.
  public static let stakingDetailsAnnualPercentageRateInfo = Localization.tr("Localizable", "staking_details_annual_percentage_rate_info")
  /// Annual percentage yield
  public static let stakingDetailsAnnualPercentageYield = Localization.tr("Localizable", "staking_details_annual_percentage_yield")
  /// APY: Shows the total interest you could earn in a year with compounding. Compounding means your earned interest is added to your balance, so you also earn interest on that interest.
  public static let stakingDetailsAnnualPercentageYieldInfo = Localization.tr("Localizable", "staking_details_annual_percentage_yield_info")
  /// APR
  public static let stakingDetailsApr = Localization.tr("Localizable", "staking_details_apr")
  /// APY
  public static let stakingDetailsApy = Localization.tr("Localizable", "staking_details_apy")
  /// Rewards automatically accumulate in your staking balance daily.
  public static let stakingDetailsAutoClaimingRewardsDailyText = Localization.tr("Localizable", "staking_details_auto_claiming_rewards_daily_text")
  /// Rewards are compounded to your staking balance. Funds earned: %@
  public static func stakingDetailsAutocompoundRewardsEarned(_ p1: Any) -> String {
    return Localization.tr("Localizable", "staking_details_autocompound_rewards_earned", String(describing: p1))
  }
  /// Available
  public static let stakingDetailsAvailable = Localization.tr("Localizable", "staking_details_available")
  /// Average Reward Rate
  public static let stakingDetailsAverageRewardRate = Localization.tr("Localizable", "staking_details_average_reward_rate")
  /// How Staking Works?
  public static let stakingDetailsBannerText = Localization.tr("Localizable", "staking_details_banner_text")
  /// %@ est. profit
  public static func stakingDetailsEstimatedProfit(_ p1: Any) -> String {
    return Localization.tr("Localizable", "staking_details_estimated_profit", String(describing: p1))
  }
  /// Market position
  public static let stakingDetailsMarketRating = Localization.tr("Localizable", "staking_details_market_rating")
  /// Metrics
  public static let stakingDetailsMetricsBlockHeader = Localization.tr("Localizable", "staking_details_metrics_block_header")
  /// According to %1$@ network rules, claims are possible from %2$@. Amounts below will be credited to your account upon unstaking.
  public static func stakingDetailsMinRewardsNotification(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "staking_details_min_rewards_notification", String(describing: p1), String(describing: p2))
  }
  /// Minimum Requirement
  public static let stakingDetailsMinimumRequirement = Localization.tr("Localizable", "staking_details_minimum_requirement")
  /// No rewards available
  public static let stakingDetailsNoRewardsToClaim = Localization.tr("Localizable", "staking_details_no_rewards_to_claim")
  /// Reward claiming
  public static let stakingDetailsRewardClaiming = Localization.tr("Localizable", "staking_details_reward_claiming")
  /// Method of receiving staking rewards.\nIt can be either automatic, where the reward is credited to your address, or manual, where you need to withdraw the reward by creating a transaction to receive it.
  public static let stakingDetailsRewardClaimingInfo = Localization.tr("Localizable", "staking_details_reward_claiming_info")
  /// Reward schedule
  public static let stakingDetailsRewardSchedule = Localization.tr("Localizable", "staking_details_reward_schedule")
  /// This is a schedule that determines when participants in staking receive their rewards. The reward distribution time may vary slightly depending on the validator and network load.
  public static let stakingDetailsRewardScheduleInfo = Localization.tr("Localizable", "staking_details_reward_schedule_info")
  /// Rewards: %@
  public static func stakingDetailsRewardsToClaim(_ p1: Any) -> String {
    return Localization.tr("Localizable", "staking_details_rewards_to_claim", String(describing: p1))
  }
  /// Staking %@
  public static func stakingDetailsTitle(_ p1: Any) -> String {
    return Localization.tr("Localizable", "staking_details_title", String(describing: p1))
  }
  /// Unbonding Period
  public static let stakingDetailsUnbondingPeriod = Localization.tr("Localizable", "staking_details_unbonding_period")
  /// The period you must wait after requesting to withdraw funds from staking before the tokens become available.
  public static let stakingDetailsUnbondingPeriodInfo = Localization.tr("Localizable", "staking_details_unbonding_period_info")
  /// Warmup period
  public static let stakingDetailsWarmupPeriod = Localization.tr("Localizable", "staking_details_warmup_period")
  /// The allocated time for activating participation in staking.
  public static let stakingDetailsWarmupPeriodInfo = Localization.tr("Localizable", "staking_details_warmup_period_info")
  /// Are you sure you want to close the staking screen?
  public static let stakingDismissMessage = Localization.tr("Localizable", "staking_dismiss_message")
  /// No available validators at the moment. Please try again later.
  public static let stakingErrorNoValidatorsMessage = Localization.tr("Localizable", "staking_error_no_validators_message")
  /// Staking Unavailable
  public static let stakingErrorNoValidatorsTitle = Localization.tr("Localizable", "staking_error_no_validators_title")
  /// The network will charge a token approval fee to verify that you are authorizing the use of your token for the staking.
  public static let stakingGivePermissionFeeFooter = Localization.tr("Localizable", "staking_give_permission_fee_footer")
  /// By using staking functionality, you agree with provider’s %1$@ and %2$@
  public static func stakingLegal(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "staking_legal", String(describing: p1), String(describing: p2))
  }
  /// Locked
  public static let stakingLocked = Localization.tr("Localizable", "staking_locked")
  /// Maximum amount: %@
  public static func stakingMaxAmountRequirementError(_ p1: Any) -> String {
    return Localization.tr("Localizable", "staking_max_amount_requirement_error", String(describing: p1))
  }
  /// Migrate
  public static let stakingMigrate = Localization.tr("Localizable", "staking_migrate")
  /// Native staking
  public static let stakingNative = Localization.tr("Localizable", "staking_native")
  /// No active validators available for staking at the moment. Please try again later.
  public static let stakingNoValidatorsErrorMessage = Localization.tr("Localizable", "staking_no_validators_error_message")
  /// When staking on the Cardano network, your entire balance is used. An additional 2 ADA will be reserved and returned after unstaking. Your ADA remains unlocked while staking.
  public static let stakingNotificationAdditionalAdaDepositText = Localization.tr("Localizable", "staking_notification_additional_ada_deposit_text")
  /// ADA Staking Details
  public static let stakingNotificationAdditionalAdaDepositTitle = Localization.tr("Localizable", "staking_notification_additional_ada_deposit_title")
  /// Earned rewards will be sent to your wallet and available for use immediately
  public static let stakingNotificationClaimRewardsText = Localization.tr("Localizable", "staking_notification_claim_rewards_text")
  /// Tangem allows users to stake their crypto
  public static let stakingNotificationEarnRewardsText = Localization.tr("Localizable", "staking_notification_earn_rewards_text")
  /// Tangem allows users to stake their crypto
  public static let stakingNotificationEarnRewardsTextDaily = Localization.tr("Localizable", "staking_notification_earn_rewards_text_daily")
  /// Tangem allows users to stake their crypto
  public static let stakingNotificationEarnRewardsTextHourly = Localization.tr("Localizable", "staking_notification_earn_rewards_text_hourly")
  /// Tangem allows users to stake their crypto
  public static let stakingNotificationEarnRewardsTextMonthly = Localization.tr("Localizable", "staking_notification_earn_rewards_text_monthly")
  /// Staking allows you to receive %1$@. Your staking rewards arrive every day.
  public static func stakingNotificationEarnRewardsTextPeriodDay(_ p1: Any) -> String {
    return Localization.tr("Localizable", "staking_notification_earn_rewards_text_period_day", String(describing: p1))
  }
  /// Staking allows you to receive %1$@. Your staking rewards arrive every hour.
  public static func stakingNotificationEarnRewardsTextPeriodHour(_ p1: Any) -> String {
    return Localization.tr("Localizable", "staking_notification_earn_rewards_text_period_hour", String(describing: p1))
  }
  /// Staking allows you to receive %1$@. Your staking rewards arrive every month.
  public static func stakingNotificationEarnRewardsTextPeriodMonth(_ p1: Any) -> String {
    return Localization.tr("Localizable", "staking_notification_earn_rewards_text_period_month", String(describing: p1))
  }
  /// Staking allows you to receive %1$@. Your staking rewards arrive every week.
  public static func stakingNotificationEarnRewardsTextPeriodWeek(_ p1: Any) -> String {
    return Localization.tr("Localizable", "staking_notification_earn_rewards_text_period_week", String(describing: p1))
  }
  /// Tangem allows users to stake their crypto
  public static let stakingNotificationEarnRewardsTextWeekly = Localization.tr("Localizable", "staking_notification_earn_rewards_text_weekly")
  /// Earn staking rewards
  public static let stakingNotificationEarnRewardsTitle = Localization.tr("Localizable", "staking_notification_earn_rewards_title")
  /// Your remaining staked balance will be too low to unstake. You’ll need to stake more to meet the minimum unstake amount.
  public static let stakingNotificationLowStakedBalanceText = Localization.tr("Localizable", "staking_notification_low_staked_balance_text")
  /// Low staked balance
  public static let stakingNotificationLowStakedBalanceTitle = Localization.tr("Localizable", "staking_notification_low_staked_balance_title")
  /// A minimum of %1$@ %2$@ is required for restaking. Please top up your balance.
  public static func stakingNotificationMinimumBalanceErrorText(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "staking_notification_minimum_balance_error_text", String(describing: p1), String(describing: p2))
  }
  /// Not enough %@
  public static func stakingNotificationMinimumBalanceErrorTitle(_ p1: Any) -> String {
    return Localization.tr("Localizable", "staking_notification_minimum_balance_error_title", String(describing: p1))
  }
  /// Insufficient Balance for Staking
  public static let stakingNotificationMinimumBalanceTitle = Localization.tr("Localizable", "staking_notification_minimum_balance_title")
  /// A minimum of 3 ADA is required for restaking. Please top up your balance.
  public static let stakingNotificationMinimumRestakeAdaText = Localization.tr("Localizable", "staking_notification_minimum_restake_ada_text")
  /// Not enough ADA
  public static let stakingNotificationMinimumRestakeAdaTitle = Localization.tr("Localizable", "staking_notification_minimum_restake_ada_title")
  /// The minimum amount required for staking must exceed 5 ADA. Please top up your balance to start staking.
  public static let stakingNotificationMinimumStakeAdaText = Localization.tr("Localizable", "staking_notification_minimum_stake_ada_text")
  /// Staking is currently unavailable due to network conditions. Please try again later.
  public static let stakingNotificationNetworkErrorText = Localization.tr("Localizable", "staking_notification_network_error_text")
  /// Staking on the %1$@ network with a new validator will automatically transfer all previously staked funds to this validator.
  public static func stakingNotificationNewValidatorFundsTransfer(_ p1: Any) -> String {
    return Localization.tr("Localizable", "staking_notification_new_validator_funds_transfer", String(describing: p1))
  }
  /// Reinvests your earned rewards in your staked amount, increasing potential earnings.
  public static let stakingNotificationRestakeRewardsText = Localization.tr("Localizable", "staking_notification_restake_rewards_text")
  /// Restake lets you move your funds from one validator to another without the need to unstake
  public static let stakingNotificationRestakeText = Localization.tr("Localizable", "staking_notification_restake_text")
  /// If you stake your entire balance, you’ll need to pay a network fee when you unstake. We recommend leaving a small amount in your wallet to cover network fees.
  public static let stakingNotificationStakeEntireBalanceText = Localization.tr("Localizable", "staking_notification_stake_entire_balance_text")
  /// To begin staking, you need to activate your TON account first.
  public static let stakingNotificationTonAccountInitializationMessage = Localization.tr("Localizable", "staking_notification_ton_account_initialization_message")
  /// Account activation
  public static let stakingNotificationTonAccountInitializationTitle = Localization.tr("Localizable", "staking_notification_ton_account_initialization_title")
  /// To start staking in TON, first send a small transaction to your own address — this will activate your wallet.
  public static let stakingNotificationTonActivateAccount = Localization.tr("Localizable", "staking_notification_ton_activate_account")
  /// Up to 0.2 TON may be required in addition to the network fee to complete the transaction. Any unused amount will be refunded.
  public static let stakingNotificationTonExtraReserveInfo = Localization.tr("Localizable", "staking_notification_ton_extra_reserve_info")
  /// 0.2 TON is required to proceed with this operation, in addition to the network fee. Please top up your balance.
  public static let stakingNotificationTonExtraReserveIsRequired = Localization.tr("Localizable", "staking_notification_ton_extra_reserve_is_required")
  /// TON reserve required
  public static let stakingNotificationTonExtraReserveTitle = Localization.tr("Localizable", "staking_notification_ton_extra_reserve_title")
  /// This action will close other positions or switch them to withdrawal status, according to network rules.
  public static let stakingNotificationTonHaveToUnstakeAllText = Localization.tr("Localizable", "staking_notification_ton_have_to_unstake_all_text")
  /// Positions status
  public static let stakingNotificationTonHaveToUnstakeAllTitle = Localization.tr("Localizable", "staking_notification_ton_have_to_unstake_all_title")
  /// Unlock your money to withdraw it from staking process. Unlocking takes %@.
  public static func stakingNotificationUnlockText(_ p1: Any) -> String {
    return Localization.tr("Localizable", "staking_notification_unlock_text", String(describing: p1))
  }
  /// Your funds will be available for use after the 21-day unbonding period. Reward will be withdrawn along with your unstaking funds.
  public static let stakingNotificationUnstakeCosmosText = Localization.tr("Localizable", "staking_notification_unstake_cosmos_text")
  /// Your funds will be available for use after the %@ unbonding period.
  public static func stakingNotificationUnstakeText(_ p1: Any) -> String {
    return Localization.tr("Localizable", "staking_notification_unstake_text", String(describing: p1))
  }
  /// You can now withdraw your funds, it will be available to use immediately
  public static let stakingNotificationWithdrawText = Localization.tr("Localizable", "staking_notification_withdraw_text")
  /// Staking in the Tron network with a new validator will automatically transfer all previously staked funds to this validator
  public static let stakingNotificationsRevoteTronText = Localization.tr("Localizable", "staking_notifications_revote_tron_text")
  /// Preparing
  public static let stakingPreparing = Localization.tr("Localizable", "staking_preparing")
  /// Ready to withdraw
  public static let stakingReadyToWithdraw = Localization.tr("Localizable", "staking_ready_to_withdraw")
  /// Rebond
  public static let stakingRebond = Localization.tr("Localizable", "staking_rebond")
  /// Restake
  public static let stakingRestake = Localization.tr("Localizable", "staking_restake")
  /// Restake rewards
  public static let stakingRestakeRewards = Localization.tr("Localizable", "staking_restake_rewards")
  /// Revoke
  public static let stakingRevoke = Localization.tr("Localizable", "staking_revoke")
  /// Revote
  public static let stakingRevote = Localization.tr("Localizable", "staking_revote")
  /// Auto
  public static let stakingRewardClaimingAuto = Localization.tr("Localizable", "staking_reward_claiming_auto")
  /// Manual
  public static let stakingRewardClaimingManual = Localization.tr("Localizable", "staking_reward_claiming_manual")
  /// Daily
  public static let stakingRewardScheduleDay = Localization.tr("Localizable", "staking_reward_schedule_day")
  /// Each %@ days
  public static func stakingRewardScheduleEachDays(_ p1: Any) -> String {
    return Localization.tr("Localizable", "staking_reward_schedule_each_days", String(describing: p1))
  }
  /// Each
  public static let stakingRewardScheduleEachPlural = Localization.tr("Localizable", "staking_reward_schedule_each_plural")
  /// Each %1$@ sec
  public static func stakingRewardScheduleEachSec(_ p1: Any) -> String {
    return Localization.tr("Localizable", "staking_reward_schedule_each_sec", String(describing: p1))
  }
  /// Rewards
  public static let stakingRewards = Localization.tr("Localizable", "staking_rewards")
  /// Rewards on Solana are automatically added to your staking balance and cannot be shown separately.
  public static let stakingSolanaDetailsAutoClaimingRewardsDailyText = Localization.tr("Localizable", "staking_solana_details_auto_claiming_rewards_daily_text")
  /// Stake locked
  public static let stakingStakeLocked = Localization.tr("Localizable", "staking_stake_locked")
  /// Stake more
  public static let stakingStakeMore = Localization.tr("Localizable", "staking_stake_more")
  /// When staking %1$@, your entire %2$@ balance is staked. Any additional %2$@ you deposit to your Tangem Wallet will also be automatically staked.
  public static func stakingStakeMoreButtonUnavailabilityReason(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "staking_stake_more_button_unavailability_reason", String(describing: p1), String(describing: p2))
  }
  /// Staked amount
  public static let stakingStakedAmount = Localization.tr("Localizable", "staking_staked_amount")
  /// You stake %1$@ and will be receiving your reward %2$@
  public static func stakingSummaryDescriptionText(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "staking_summary_description_text", String(describing: p1), String(describing: p2))
  }
  /// Tap to unlock
  public static let stakingTapToUnlock = Localization.tr("Localizable", "staking_tap_to_unlock")
  /// Tap to unlock or vote
  public static let stakingTapToUnlockOrVote = Localization.tr("Localizable", "staking_tap_to_unlock_or_vote")
  /// Tap to withdraw
  public static let stakingTapToWithdraw = Localization.tr("Localizable", "staking_tap_to_withdraw")
  /// Stake %@
  public static func stakingTitleStake(_ p1: Any) -> String {
    return Localization.tr("Localizable", "staking_title_stake", String(describing: p1))
  }
  /// Unstake %@
  public static func stakingTitleUnstake(_ p1: Any) -> String {
    return Localization.tr("Localizable", "staking_title_unstake", String(describing: p1))
  }
  /// The transaction is being processed! Validation is currently underway in the blockchain. This may take a few minutes.
  public static let stakingTransactionInProgressText = Localization.tr("Localizable", "staking_transaction_in_progress_text")
  /// Unbonding
  public static let stakingUnbonding = Localization.tr("Localizable", "staking_unbonding")
  /// Unbonding in
  public static let stakingUnbondingIn = Localization.tr("Localizable", "staking_unbonding_in")
  /// Unlock
  public static let stakingUnlockedLocked = Localization.tr("Localizable", "staking_unlocked_locked")
  /// Unlocking
  public static let stakingUnlocking = Localization.tr("Localizable", "staking_unlocking")
  /// The amount to unstake must be at least %@
  public static func stakingUnstakeAmountRequirementError(_ p1: Any) -> String {
    return Localization.tr("Localizable", "staking_unstake_amount_requirement_error", String(describing: p1))
  }
  /// Amount exceeds staked balance
  public static let stakingUnstakeAmountValidationError = Localization.tr("Localizable", "staking_unstake_amount_validation_error")
  /// Unstaked
  public static let stakingUnstaked = Localization.tr("Localizable", "staking_unstaked")
  /// Check unstaked to claim your assets
  public static let stakingUnstakedFooter = Localization.tr("Localizable", "staking_unstaked_footer")
  /// Unstaking
  public static let stakingUnstaking = Localization.tr("Localizable", "staking_unstaking")
  /// Unstaking assets %@
  public static func stakingUnstakingItemName(_ p1: Any) -> String {
    return Localization.tr("Localizable", "staking_unstaking_item_name", String(describing: p1))
  }
  /// Validator
  public static let stakingValidator = Localization.tr("Localizable", "staking_validator")
  /// Validators
  public static let stakingValidators = Localization.tr("Localizable", "staking_validators")
  /// Strategic partner
  public static let stakingValidatorsLabel = Localization.tr("Localizable", "staking_validators_label")
  /// Vote
  public static let stakingVote = Localization.tr("Localizable", "staking_vote")
  /// Vote
  public static let stakingVoteLocked = Localization.tr("Localizable", "staking_vote_locked")
  /// Withdraw
  public static let stakingWithdraw = Localization.tr("Localizable", "staking_withdraw")
  /// Your stakes
  public static let stakingYourStakes = Localization.tr("Localizable", "staking_your_stakes")
  /// Store your crypto assets secure while keeping private keys contained in your card or ring
  public static let storyAweDescription = Localization.tr("Localizable", "story_awe_description")
  /// Revolutionary Hardware Wallet
  public static let storyAweTitle = Localization.tr("Localizable", "story_awe_title")
  /// Add up to 3 cards or rings to one wallet
  public static let storyBackupDescription = Localization.tr("Localizable", "story_backup_description")
  /// Ultra Secure Backup
  public static let storyBackupTitle = Localization.tr("Localizable", "story_backup_title")
  /// A hardware wallet for your Bitcoin, Ethereum and many more currencies simultaneously — all in one card or ring
  public static let storyCurrenciesDescription = Localization.tr("Localizable", "story_currencies_description")
  /// Thousands of Currencies
  public static let storyCurrenciesTitle = Localization.tr("Localizable", "story_currencies_title")
  /// Use it on the go, anywhere, anytime. No wires or batteries. Just tap the card or ring to your phone when you need your crypto.
  public static let storyFinishDescription = Localization.tr("Localizable", "story_finish_description")
  /// The Wallet for Everyone
  public static let storyFinishTitle = Localization.tr("Localizable", "story_finish_title")
  /// Take three lessons, get a discount on your Tangem Wallet, and receive 1INCH tokens to your wallet
  public static let storyLearnDescription = Localization.tr("Localizable", "story_learn_description")
  /// Learn
  public static let storyLearnLearn = Localization.tr("Localizable", "story_learn_learn")
  /// Meet Tangem
  public static let storyMeetTitle = Localization.tr("Localizable", "story_meet_title")
  /// More than 100 decentralized service integrations are available
  public static let storyWeb3Description = Localization.tr("Localizable", "story_web3_description")
  /// Web 3.0 Compatible
  public static let storyWeb3Title = Localization.tr("Localizable", "story_web3_title")
  /// An incoming transaction of at least %1$@ is required to proceed
  public static func suiNotEnoughCoinForFeeDescription(_ p1: Any) -> String {
    return Localization.tr("Localizable", "sui_not_enough_coin_for_fee_description", String(describing: p1))
  }
  /// Insufficient funds
  public static let suiNotEnoughCoinForFeeTitle = Localization.tr("Localizable", "sui_not_enough_coin_for_fee_title")
  /// By approving, you allow the smart contract to use your tokens in future transactions.
  public static let swapApproveDescription = Localization.tr("Localizable", "swap_approve_description")
  /// Fixed Rate
  public static let swapFixedRate = Localization.tr("Localizable", "swap_fixed_rate")
  /// The network will charge a token approval fee to verify that you are authorizing the use of your token for the swap.
  public static let swapGivePermissionFeeFooter = Localization.tr("Localizable", "swap_give_permission_fee_footer")
  /// Feel confident with round-the-clock support to help with any issues
  public static let swapStoryFifthSubtitle = Localization.tr("Localizable", "swap_story_fifth_subtitle")
  /// Always Here
  public static let swapStoryFifthTitle = Localization.tr("Localizable", "swap_story_fifth_title")
  /// Multiple trusted providers in one place—swap any asset effortlessly in your wallet
  public static let swapStoryFirstSubtitle = Localization.tr("Localizable", "swap_story_first_subtitle")
  /// Swap With Us
  public static let swapStoryFirstTitle = Localization.tr("Localizable", "swap_story_first_title")
  /// No fumbles, no turnovers, no blind spots—your transaction is always protected
  public static let swapStoryForthSubtitle = Localization.tr("Localizable", "swap_story_forth_subtitle")
  /// Impenetrable Defense
  public static let swapStoryForthTitle = Localization.tr("Localizable", "swap_story_forth_title")
  /// Maximize your value with rates sourced from a wide network of trusted providers, always choosing the best one
  public static let swapStorySecondSubtitle = Localization.tr("Localizable", "swap_story_second_subtitle")
  /// Unbeatable Rates
  public static let swapStorySecondTitle = Localization.tr("Localizable", "swap_story_second_title")
  /// Hassle-free and intuitive, allowing you to swap tokens in just a few taps
  public static let swapStoryThirdSubtitle = Localization.tr("Localizable", "swap_story_third_subtitle")
  /// Simply Convenient
  public static let swapStoryThirdTitle = Localization.tr("Localizable", "swap_story_third_title")
  /// Swap via provider
  public static let swapViaProvider = Localization.tr("Localizable", "swap_via_provider")
  /// Your assets
  public static let swapYourAssetsTitle = Localization.tr("Localizable", "swap_your_assets_title")
  /// The amount includes:\n• service provider's fee\n• network fee for sending %@ from the exchange back to the user's address.
  public static func swappingAlertCexDescription(_ p1: Any) -> String {
    return Localization.tr("Localizable", "swapping_alert_cex_description", String(describing: p1))
  }
  /// The amount includes:\n• service provider's fee\n• network fee for sending %1$@ from the exchange back to the user's address. \n\nProvider slippage is up to %2$@
  public static func swappingAlertCexDescriptionWithSlippage(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "swapping_alert_cex_description_with_slippage", String(describing: p1), String(describing: p2))
  }
  /// The amount includes the service provider's fee.
  public static let swappingAlertDexDescription = Localization.tr("Localizable", "swapping_alert_dex_description")
  /// The amount includes the service provider's fee. \n\nProvider slippage is up to %@
  public static func swappingAlertDexDescriptionWithSlippage(_ p1: Any) -> String {
    return Localization.tr("Localizable", "swapping_alert_dex_description_with_slippage", String(describing: p1))
  }
  /// Information
  public static let swappingAlertTitle = Localization.tr("Localizable", "swapping_alert_title")
  /// All decentralized exchanges require approvals to prevent smart contracts from accessing your wallet without your permission. By design, smart contracts can't access your tokens unless you approve. By "unlocking" your tokens, you authorize the 1-inch smart contract to spend them. The network's miners receive a gas fee (paid by you) to record this action on the blockchain. You can swap your token after giving approval.
  public static let swappingApproveInformationText = Localization.tr("Localizable", "swapping_approve_information_text")
  /// Approve
  public static let swappingApproveInformationTitle = Localization.tr("Localizable", "swapping_approve_information_title")
  /// Fee estimation error. Please send feedback to support.
  public static let swappingFeeEstimationErrorText = Localization.tr("Localizable", "swapping_fee_estimation_error_text")
  /// You swap
  public static let swappingFromTitle = Localization.tr("Localizable", "swapping_from_title")
  /// Swapping this amount of selected tokens will cause a significant price impact and reduce your outcome.
  public static let swappingHighPriceImpactDescription = Localization.tr("Localizable", "swapping_high_price_impact_description")
  /// High price impact
  public static let swappingHighPriceImpactTitle = Localization.tr("Localizable", "swapping_high_price_impact_title")
  /// Insufficient funds
  public static let swappingInsufficientFunds = Localization.tr("Localizable", "swapping_insufficient_funds")
  /// Give Permission
  public static let swappingPermissionHeader = Localization.tr("Localizable", "swapping_permission_header")
  /// Permit and Swap
  public static let swappingPermitAndSwap = Localization.tr("Localizable", "swapping_permit_and_swap")
  /// Swap
  public static let swappingSwapAction = Localization.tr("Localizable", "swapping_swap_action")
  /// Swapping...
  public static let swappingSwapActionInProgress = Localization.tr("Localizable", "swapping_swap_action_in_progress")
  /// You receive
  public static let swappingToTitle = Localization.tr("Localizable", "swapping_to_title")
  /// Choose token
  public static let swappingTokenListTitle = Localization.tr("Localizable", "swapping_token_list_title")
  /// not available
  public static let swappingTokenNotAvailable = Localization.tr("Localizable", "swapping_token_not_available")
  /// We would be happy to receive your feedback
  public static let tangemPayBetaNotificationSubtitle = Localization.tr("Localizable", "tangem_pay_beta_notification_subtitle")
  /// Tangem Pay is now in beta
  public static let tangemPayBetaNotificationTitle = Localization.tr("Localizable", "tangem_pay_beta_notification_title")
  /// Card frozen
  public static let tangemPayCardFrozen = Localization.tr("Localizable", "tangem_pay_card_frozen")
  /// Card payment
  public static let tangemPayCardPayment = Localization.tr("Localizable", "tangem_pay_card_payment")
  /// Deposit
  public static let tangemPayDeposit = Localization.tr("Localizable", "tangem_pay_deposit")
  /// Dispute
  public static let tangemPayDispute = Localization.tr("Localizable", "tangem_pay_dispute")
  /// Explore transaction
  public static let tangemPayExploreTransaction = Localization.tr("Localizable", "tangem_pay_explore_transaction")
  /// Service fees
  public static let tangemPayFeeSubtitle = Localization.tr("Localizable", "tangem_pay_fee_subtitle")
  /// Fee
  public static let tangemPayFeeTitle = Localization.tr("Localizable", "tangem_pay_fee_title")
  /// Keep your money safe. You can unfreeze anytime.
  public static let tangemPayFreezeCardAlertBody = Localization.tr("Localizable", "tangem_pay_freeze_card_alert_body")
  /// Freeze your card?
  public static let tangemPayFreezeCardAlertTitle = Localization.tr("Localizable", "tangem_pay_freeze_card_alert_title")
  /// Failed to freeze the card. Try again later.
  public static let tangemPayFreezeCardFailed = Localization.tr("Localizable", "tangem_pay_freeze_card_failed")
  /// Freeze
  public static let tangemPayFreezeCardFreeze = Localization.tr("Localizable", "tangem_pay_freeze_card_freeze")
  /// Your card is frozen.
  public static let tangemPayFreezeCardSuccess = Localization.tr("Localizable", "tangem_pay_freeze_card_success")
  /// Get Help
  public static let tangemPayGetHelp = Localization.tr("Localizable", "tangem_pay_get_help")
  /// Reason: %@
  public static func tangemPayHistoryItemSpendMcDeclinedReason(_ p1: Any) -> String {
    return Localization.tr("Localizable", "tangem_pay_history_item_spend_mc_declined_reason", String(describing: p1))
  }
  /// %@ · %@
  public static func tangemPayHistoryItemSpendMcTitleFormat(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "tangem_pay_history_item_spend_mc_title_format", String(describing: p1), String(describing: p2))
  }
  /// MCC %@
  public static func tangemPayHistoryItemSpendMcc(_ p1: Any) -> String {
    return Localization.tr("Localizable", "tangem_pay_history_item_spend_mcc", String(describing: p1))
  }
  /// Other
  public static let tangemPayOther = Localization.tr("Localizable", "tangem_pay_other")
  /// Unable to use on rooted devices
  public static let tangemPayRootedDeviceSubtitle = Localization.tr("Localizable", "tangem_pay_rooted_device_subtitle")
  /// Completed
  public static let tangemPayStatusCompleted = Localization.tr("Localizable", "tangem_pay_status_completed")
  /// Declined
  public static let tangemPayStatusDeclined = Localization.tr("Localizable", "tangem_pay_status_declined")
  /// Pending
  public static let tangemPayStatusPending = Localization.tr("Localizable", "tangem_pay_status_pending")
  /// Reversed
  public static let tangemPayStatusReversed = Localization.tr("Localizable", "tangem_pay_status_reversed")
  /// Terms, Fees & Limits
  public static let tangemPayTermsFeesLimits = Localization.tr("Localizable", "tangem_pay_terms_fees_limits")
  /// Terms and Limits
  public static let tangemPayTermsLimits = Localization.tr("Localizable", "tangem_pay_terms_limits")
  /// The bank rejected this transaction request.
  public static let tangemPayTransactionDeclinedNotificationText = Localization.tr("Localizable", "tangem_pay_transaction_declined_notification_text")
  /// This fee goes to cover the cost of handling your transfer.
  public static let tangemPayTransactionFeeNotificationText = Localization.tr("Localizable", "tangem_pay_transaction_fee_notification_text")
  /// The transaction was partially or fully reversed by the merchant
  public static let tangemPayTransactionReversedNotificationText = Localization.tr("Localizable", "tangem_pay_transaction_reversed_notification_text")
  /// Keep using your money. You can freeze anytime.
  public static let tangemPayUnfreezeCardAlertBody = Localization.tr("Localizable", "tangem_pay_unfreeze_card_alert_body")
  /// Unfreeze your card?
  public static let tangemPayUnfreezeCardAlertTitle = Localization.tr("Localizable", "tangem_pay_unfreeze_card_alert_title")
  /// Failed to unfreeze the card. Try again later.
  public static let tangemPayUnfreezeCardFailed = Localization.tr("Localizable", "tangem_pay_unfreeze_card_failed")
  /// Your card is unfrozen.
  public static let tangemPayUnfreezeCardSuccess = Localization.tr("Localizable", "tangem_pay_unfreeze_card_success")
  /// Withdrawal
  public static let tangemPayWithdrawal = Localization.tr("Localizable", "tangem_pay_withdrawal")
  /// Unable to use on rooted device
  public static let tangempayAccountUnableToUseRooted = Localization.tr("Localizable", "tangempay_account_unable_to_use_rooted")
  /// Cancel KYC
  public static let tangempayCancelKyc = Localization.tr("Localizable", "tangempay_cancel_kyc")
  /// Add funds
  public static let tangempayCardDetailsAddFunds = Localization.tr("Localizable", "tangempay_card_details_add_funds")
  /// Top-up options
  public static let tangempayCardDetailsAddFundsSubtitle = Localization.tr("Localizable", "tangempay_card_details_add_funds_subtitle")
  /// Card Number
  public static let tangempayCardDetailsCardNumber = Localization.tr("Localizable", "tangempay_card_details_card_number")
  /// Change PIN
  public static let tangempayCardDetailsChangePin = Localization.tr("Localizable", "tangempay_card_details_change_pin")
  /// The card is fully ready for payments.
  public static let tangempayCardDetailsChangePinSuccessDescription = Localization.tr("Localizable", "tangempay_card_details_change_pin_success_description")
  /// PIN code created
  public static let tangempayCardDetailsChangePinSuccessTitle = Localization.tr("Localizable", "tangempay_card_details_change_pin_success_title")
  /// CVC
  public static let tangempayCardDetailsCvc = Localization.tr("Localizable", "tangempay_card_details_cvc")
  /// Failed to load data. Try again later.
  public static let tangempayCardDetailsErrorText = Localization.tr("Localizable", "tangempay_card_details_error_text")
  /// Expiry
  public static let tangempayCardDetailsExpiry = Localization.tr("Localizable", "tangempay_card_details_expiry")
  /// Freeze Card
  public static let tangempayCardDetailsFreezeCard = Localization.tr("Localizable", "tangempay_card_details_freeze_card")
  /// Hide details
  public static let tangempayCardDetailsHideDetails = Localization.tr("Localizable", "tangempay_card_details_hide_details")
  /// Hide
  public static let tangempayCardDetailsHideText = Localization.tr("Localizable", "tangempay_card_details_hide_text")
  /// Open Google Wallet
  public static let tangempayCardDetailsOpenWalletButton = Localization.tr("Localizable", "tangempay_card_details_open_wallet_button")
  /// Set up Tangem Pay in a few taps and start paying with Google Pay.
  public static let tangempayCardDetailsOpenWalletNotificationSubtitle = Localization.tr("Localizable", "tangempay_card_details_open_wallet_notification_subtitle")
  /// Set up Tangem Pay in a few taps and start paying with Apple Pay.
  public static let tangempayCardDetailsOpenWalletNotificationSubtitleApple = Localization.tr("Localizable", "tangempay_card_details_open_wallet_notification_subtitle_apple")
  /// Add your card to Google Pay
  public static let tangempayCardDetailsOpenWalletNotificationTitle = Localization.tr("Localizable", "tangempay_card_details_open_wallet_notification_title")
  /// Add your card to Apple Pay
  public static let tangempayCardDetailsOpenWalletNotificationTitleApple = Localization.tr("Localizable", "tangempay_card_details_open_wallet_notification_title_apple")
  /// Open Google Wallet
  public static let tangempayCardDetailsOpenWalletStep1 = Localization.tr("Localizable", "tangempay_card_details_open_wallet_step_1")
  /// Tap “+” button on the top right
  public static let tangempayCardDetailsOpenWalletStep15Apple = Localization.tr("Localizable", "tangempay_card_details_open_wallet_step_1_5_apple")
  /// Open Apple Wallet
  public static let tangempayCardDetailsOpenWalletStep1Apple = Localization.tr("Localizable", "tangempay_card_details_open_wallet_step_1_apple")
  /// Tap “Add a card”
  public static let tangempayCardDetailsOpenWalletStep2 = Localization.tr("Localizable", "tangempay_card_details_open_wallet_step_2")
  /// Tap “Debit or Credit Card”
  public static let tangempayCardDetailsOpenWalletStep2Apple = Localization.tr("Localizable", "tangempay_card_details_open_wallet_step_2_apple")
  /// Enter the card details manually
  public static let tangempayCardDetailsOpenWalletStep3 = Localization.tr("Localizable", "tangempay_card_details_open_wallet_step_3")
  /// Verify card using the OTP sent to your device.
  public static let tangempayCardDetailsOpenWalletStep4 = Localization.tr("Localizable", "tangempay_card_details_open_wallet_step_4")
  /// All set! Your card is ready to use.
  public static let tangempayCardDetailsOpenWalletStep5 = Localization.tr("Localizable", "tangempay_card_details_open_wallet_step_5")
  /// Add card to Google Pay
  public static let tangempayCardDetailsOpenWalletTitle = Localization.tr("Localizable", "tangempay_card_details_open_wallet_title")
  /// Add card to Apple Pay
  public static let tangempayCardDetailsOpenWalletTitleApple = Localization.tr("Localizable", "tangempay_card_details_open_wallet_title_apple")
  /// PIN code
  public static let tangempayCardDetailsPinCode = Localization.tr("Localizable", "tangempay_card_details_pin_code")
  /// Share your address or show QR-code
  public static let tangempayCardDetailsReceiveDescription = Localization.tr("Localizable", "tangempay_card_details_receive_description")
  /// Technical issues detected. Please try again later or contact support.
  public static let tangempayCardDetailsReceiveErrorDescription = Localization.tr("Localizable", "tangempay_card_details_receive_error_description")
  /// Receive unavailable now
  public static let tangempayCardDetailsReceiveErrorTitle = Localization.tr("Localizable", "tangempay_card_details_receive_error_title")
  /// Reveal
  public static let tangempayCardDetailsRevealText = Localization.tr("Localizable", "tangempay_card_details_reveal_text")
  /// Show details
  public static let tangempayCardDetailsShowDetails = Localization.tr("Localizable", "tangempay_card_details_show_details")
  /// Swap any asset in your portfolio for card
  public static let tangempayCardDetailsSwapDescription = Localization.tr("Localizable", "tangempay_card_details_swap_description")
  /// Card details
  public static let tangempayCardDetailsTitle = Localization.tr("Localizable", "tangempay_card_details_title")
  /// Unfreeze Card
  public static let tangempayCardDetailsUnfreezeCard = Localization.tr("Localizable", "tangempay_card_details_unfreeze_card")
  /// Come back to the app if you forget it.
  public static let tangempayCardDetailsViewPinCodeDescription = Localization.tr("Localizable", "tangempay_card_details_view_pin_code_description")
  /// Your PIN code
  public static let tangempayCardDetailsViewPinCodeTitle = Localization.tr("Localizable", "tangempay_card_details_view_pin_code_title")
  /// Withdraw
  public static let tangempayCardDetailsWithdraw = Localization.tr("Localizable", "tangempay_card_details_withdraw")
  /// Withdraw unavailable now
  public static let tangempayCardDetailsWithdrawErrorTitle = Localization.tr("Localizable", "tangempay_card_details_withdraw_error_title")
  /// You can't initiate swap or new withdrawal till the current one is finished
  public static let tangempayCardDetailsWithdrawInProgressDescription = Localization.tr("Localizable", "tangempay_card_details_withdraw_in_progress_description")
  /// Withdrawal in progress
  public static let tangempayCardDetailsWithdrawInProgressTitle = Localization.tr("Localizable", "tangempay_card_details_withdraw_in_progress_title")
  /// Change PIN-code
  public static let tangempayChangePinCode = Localization.tr("Localizable", "tangempay_change_pin_code")
  /// Come back to the app if you forget it.
  public static let tangempayComeBackIfForgetPin = Localization.tr("Localizable", "tangempay_come_back_if_forget_pin")
  /// I understand that I will completely lose access to my Tangem Pay Card and all funds on it without the possibility of recovery
  public static let tangempayFactorySettingsWarningTitle = Localization.tr("Localizable", "tangempay_factory_settings_warning_title")
  /// Failed to issue card
  public static let tangempayFailedToIssueCard = Localization.tr("Localizable", "tangempay_failed_to_issue_card")
  /// A technical error has occurred, please try again by clicking the button below.
  public static let tangempayFailedToIssueCardRetryDescription = Localization.tr("Localizable", "tangempay_failed_to_issue_card_retry_description")
  /// A technical error has occurred, please contact support.
  public static let tangempayFailedToIssueCardSupportDescription = Localization.tr("Localizable", "tangempay_failed_to_issue_card_support_description")
  /// Get your free Tangem Visa virtual card
  public static let tangempayGetBannerDescription = Localization.tr("Localizable", "tangempay_get_banner_description")
  /// Get Tangem Pay
  public static let tangempayGetTangemPay = Localization.tr("Localizable", "tangempay_get_tangem_pay")
  /// Go to Support
  public static let tangempayGoToSupport = Localization.tr("Localizable", "tangempay_go_to_support")
  /// It usually takes up to 15 minutes
  public static let tangempayIssueCardNotificationDescription = Localization.tr("Localizable", "tangempay_issue_card_notification_description")
  /// Setting up your Tangem Card
  public static let tangempayIssueCardNotificationTitle = Localization.tr("Localizable", "tangempay_issue_card_notification_title")
  /// Issuing your card
  public static let tangempayIssuingYourCard = Localization.tr("Localizable", "tangempay_issuing_your_card")
  /// The card is usually issued automatically within 5 minutes. In rare cases, if manual review is required, it may take up to 48 hours.
  public static let tangempayIssuingYourCardDescription = Localization.tr("Localizable", "tangempay_issuing_your_card_description")
  /// Tangem Pay
  public static let tangempayKycCardReadyNotificationTitle = Localization.tr("Localizable", "tangempay_kyc_card_ready_notification_title")
  /// Confirm Cancellation
  public static let tangempayKycConfirmCancellationAlertTitle = Localization.tr("Localizable", "tangempay_kyc_confirm_cancellation_alert_title")
  /// Are you sure you want to stop the KYC process? You can return to it anytime.
  public static let tangempayKycConfirmCancellationDescription = Localization.tr("Localizable", "tangempay_kyc_confirm_cancellation_description")
  /// We could not verify your profile. If you have any questions, please contact support.
  public static let tangempayKycFailedDescription = Localization.tr("Localizable", "tangempay_kyc_failed_description")
  /// Unfortunately, we couldn't verify your identity 
  public static let tangempayKycFailedTitle = Localization.tr("Localizable", "tangempay_kyc_failed_title")
  /// KYC has failed
  public static let tangempayKycHasFailed = Localization.tr("Localizable", "tangempay_kyc_has_failed")
  /// KYC in progress
  public static let tangempayKycInProgress = Localization.tr("Localizable", "tangempay_kyc_in_progress")
  /// View Status
  public static let tangempayKycInProgressNotificationButton = Localization.tr("Localizable", "tangempay_kyc_in_progress_notification_button")
  /// KYC in progress for Tangem Pay
  public static let tangempayKycInProgressNotificationTitle = Localization.tr("Localizable", "tangempay_kyc_in_progress_notification_title")
  /// Documents are usually verified automatically within 5 minutes. In rare cases, if manual review is required, it may take up to 48 hours.
  public static let tangempayKycInProgressPopupDescription = Localization.tr("Localizable", "tangempay_kyc_in_progress_popup_description")
  /// KYC rejected
  public static let tangempayKycRejected = Localization.tr("Localizable", "tangempay_kyc_rejected")
  /// Hide KYC block
  public static let tangempayKycRejectedButtonText = Localization.tr("Localizable", "tangempay_kyc_rejected_button_text")
  /// Sorry, we couldn't verify
  public static let tangempayKycRejectedDescription = Localization.tr("Localizable", "tangempay_kyc_rejected_description")
  /// your profile.
  public static let tangempayKycRejectedDescriptionSpan = Localization.tr("Localizable", "tangempay_kyc_rejected_description_span")
  /// Get your free Tangem Visa virtual card
  public static let tangempayOnboardingBannerDescription = Localization.tr("Localizable", "tangempay_onboarding_banner_description")
  /// Use USDC for everyday payments
  public static let tangempayOnboardingBannerTitle = Localization.tr("Localizable", "tangempay_onboarding_banner_title")
  /// Get card
  public static let tangempayOnboardingGetCardButtonText = Localization.tr("Localizable", "tangempay_onboarding_get_card_button_text")
  /// With digital card that works with Apple Pay and Google Pay
  public static let tangempayOnboardingPayDescription = Localization.tr("Localizable", "tangempay_onboarding_pay_description")
  /// Spend your assets anywhere
  public static let tangempayOnboardingPayTitle = Localization.tr("Localizable", "tangempay_onboarding_pay_title")
  /// There are no additional fees for purchases
  public static let tangempayOnboardingPurchasesDescription = Localization.tr("Localizable", "tangempay_onboarding_purchases_description")
  /// Pay exactly what you see
  public static let tangempayOnboardingPurchasesTitle = Localization.tr("Localizable", "tangempay_onboarding_purchases_title")
  /// A separate payment account will be created without disclosing your addresses and assets
  public static let tangempayOnboardingSecurityDescription = Localization.tr("Localizable", "tangempay_onboarding_security_description")
  /// Unrivaled privacy
  public static let tangempayOnboardingSecurityTitle = Localization.tr("Localizable", "tangempay_onboarding_security_title")
  /// Get your free Tangem Pay Card in minutes
  public static let tangempayOnboardingTitle = Localization.tr("Localizable", "tangempay_onboarding_title")
  /// Payment account
  public static let tangempayPaymentAccount = Localization.tr("Localizable", "tangempay_payment_account")
  /// Payment account is not synced
  public static let tangempayPaymentAccountSyncNeeded = Localization.tr("Localizable", "tangempay_payment_account_sync_needed")
  /// Invalid PIN: avoid sequences or repeats
  public static let tangempayPinValidationErrorMessage = Localization.tr("Localizable", "tangempay_pin_validation_error_message")
  /// We’re fixing a technical issue. Please try again later.
  public static let tangempayServiceUnavailableDescription = Localization.tr("Localizable", "tangempay_service_unavailable_description")
  /// Service temporarily unavailable
  public static let tangempayServiceUnavailableTitle = Localization.tr("Localizable", "tangempay_service_unavailable_title")
  /// Unable to display details. However, card payments are still working.
  public static let tangempayServiceUnreachableTryLater = Localization.tr("Localizable", "tangempay_service_unreachable_try_later")
  /// Set \nPIN code
  public static let tangempaySetPinCode = Localization.tr("Localizable", "tangempay_set_pin_code")
  /// Not synced
  public static let tangempaySyncNeeded = Localization.tr("Localizable", "tangempay_sync_needed")
  /// Restore access
  public static let tangempaySyncNeededRestoreAccess = Localization.tr("Localizable", "tangempay_sync_needed_restore_access")
  /// Use USDC for everyday payments
  public static let tangempayTangemVisaCard = Localization.tr("Localizable", "tangempay_tangem_visa_card")
  /// Tangem Pay is temporarily unreachable
  public static let tangempayTemporarilyUnavailable = Localization.tr("Localizable", "tangempay_temporarily_unavailable")
  /// Tangem Pay
  public static let tangempayTitle = Localization.tr("Localizable", "tangempay_title")
  /// Click the button below to restore access
  public static let tangempayUseTangemDeviceToRestorePaymentAccount = Localization.tr("Localizable", "tangempay_use_tangem_device_to_restore_payment_account")
  /// Your on-chain USDC Polygon balance differs from your card balance and updates within 2 business days after a purchase. Funds from refunded purchases won’t be returned your on-chain balance or be available for withdrawal, but will stay on your card balance for purchases.
  public static let tangempayWithdrawalNoteDescription = Localization.tr("Localizable", "tangempay_withdrawal_note_description")
  /// Please note
  public static let tangempayWithdrawalNoteTitle = Localization.tr("Localizable", "tangempay_withdrawal_note_title")
  /// Your PIN code
  public static let tangempayYourPinCode = Localization.tr("Localizable", "tangempay_your_pin_code")
  /// This is my wallet
  public static let thisIsMyWalletTitle = Localization.tr("Localizable", "this_is_my_wallet_title")
  /// Balances hidden
  public static let toastBalancesHidden = Localization.tr("Localizable", "toast_balances_hidden")
  /// Balances shown
  public static let toastBalancesShown = Localization.tr("Localizable", "toast_balances_shown")
  /// Undo
  public static let toastUndo = Localization.tr("Localizable", "toast_undo")
  /// This operation is currently unavailable. Please try again later.
  public static let tokenButtonUnavailabilityGenericDescription = Localization.tr("Localizable", "token_button_unavailability_generic_description")
  /// Buying %@ is not supported by current providers, but we are working to add more options.
  public static func tokenButtonUnavailabilityReasonBuyUnavailable(_ p1: Any) -> String {
    return Localization.tr("Localizable", "token_button_unavailability_reason_buy_unavailable", String(describing: p1))
  }
  /// Action is not available for custom tokens.
  public static let tokenButtonUnavailabilityReasonCustomToken = Localization.tr("Localizable", "token_button_unavailability_reason_custom_token")
  /// You do not have funds to sell. Top up your account to be able to sell funds from it.
  public static let tokenButtonUnavailabilityReasonEmptyBalanceSell = Localization.tr("Localizable", "token_button_unavailability_reason_empty_balance_sell")
  /// You do not have funds to send. Top up your account to be able to send funds from it.
  public static let tokenButtonUnavailabilityReasonEmptyBalanceSend = Localization.tr("Localizable", "token_button_unavailability_reason_empty_balance_send")
  /// The data is currently loading. This may take a few seconds. Please try again later.
  public static let tokenButtonUnavailabilityReasonLoading = Localization.tr("Localizable", "token_button_unavailability_reason_loading")
  /// Swapping %@ is not supported by current providers, but we are working to add more options.
  public static func tokenButtonUnavailabilityReasonNotExchangeable(_ p1: Any) -> String {
    return Localization.tr("Localizable", "token_button_unavailability_reason_not_exchangeable", String(describing: p1))
  }
  /// The displayed balance might be outdated due to caching.
  public static let tokenButtonUnavailabilityReasonOutOfDateBalance = Localization.tr("Localizable", "token_button_unavailability_reason_out_of_date_balance")
  /// Selling funds will be available once the pending transaction(s) on the %@ network is complete.
  public static func tokenButtonUnavailabilityReasonPendingTransactionSell(_ p1: Any) -> String {
    return Localization.tr("Localizable", "token_button_unavailability_reason_pending_transaction_sell", String(describing: p1))
  }
  /// Sending funds will be available once the pending transaction(s) in network %@ is complete
  public static func tokenButtonUnavailabilityReasonPendingTransactionSend(_ p1: Any) -> String {
    return Localization.tr("Localizable", "token_button_unavailability_reason_pending_transaction_send", String(describing: p1))
  }
  /// Selling %@ is not supported by current providers, but we are working to add more options.
  public static func tokenButtonUnavailabilityReasonSellUnavailable(_ p1: Any) -> String {
    return Localization.tr("Localizable", "token_button_unavailability_reason_sell_unavailable", String(describing: p1))
  }
  /// Staking %@ is not supported by current providers, but we are working to add more options.
  public static func tokenButtonUnavailabilityReasonStakingUnavailable(_ p1: Any) -> String {
    return Localization.tr("Localizable", "token_button_unavailability_reason_staking_unavailable", String(describing: p1))
  }
  /// Approval has been revoked. Your funds remain in Yield mode. To perform actions, please go to Yield mode and grant permission again.
  public static let tokenButtonUnavailabilityReasonYieldSupplyApproval = Localization.tr("Localizable", "token_button_unavailability_reason_yield_supply_approval")
  /// Choose address
  public static let tokenDetailsChooseAddress = Localization.tr("Localizable", "token_details_choose_address")
  /// Generate XPUB
  public static let tokenDetailsGenerateXpub = Localization.tr("Localizable", "token_details_generate_xpub")
  /// Hide
  public static let tokenDetailsHideAlertHide = Localization.tr("Localizable", "token_details_hide_alert_hide")
  /// You are about to hide this token from the main screen. You can add it back anytime through the manage tokens page.
  public static let tokenDetailsHideAlertMessage = Localization.tr("Localizable", "token_details_hide_alert_message")
  /// Hide %@
  public static func tokenDetailsHideAlertTitle(_ p1: Any) -> String {
    return Localization.tr("Localizable", "token_details_hide_alert_title", String(describing: p1))
  }
  /// Hide token
  public static let tokenDetailsHideToken = Localization.tr("Localizable", "token_details_hide_token")
  /// Staking allows you to receive %1$@ and get rewards every %2$@ days
  public static func tokenDetailsStakingBlockSubtitle(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "token_details_staking_block_subtitle", String(describing: p1), String(describing: p2))
  }
  /// Staking Service
  public static let tokenDetailsStakingBlockTitle = Localization.tr("Localizable", "token_details_staking_block_title")
  /// %1$@ token in %%image%% %2$@ network
  public static func tokenDetailsTokenTypeSubtitle(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "token_details_token_type_subtitle", String(describing: p1), String(describing: p2))
  }
  /// Token in %%image%% %1$@ network
  public static func tokenDetailsTokenTypeSubtitleNoStandard(_ p1: Any) -> String {
    return Localization.tr("Localizable", "token_details_token_type_subtitle_no_standard", String(describing: p1))
  }
  /// The %1$@ (%2$@) token is the main currency on the %3$@ network and cannot be hidden as long as you have other tokens on this network in the list
  public static func tokenDetailsUnableHideAlertMessage(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return Localization.tr("Localizable", "token_details_unable_hide_alert_message", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// Unable to hide %@
  public static func tokenDetailsUnableHideAlertTitle(_ p1: Any) -> String {
    return Localization.tr("Localizable", "token_details_unable_hide_alert_title", String(describing: p1))
  }
  /// Show QR code
  public static let tokenReceiveShowQrCodeTitle = Localization.tr("Localizable", "token_receive_show_qr_code_title")
  /// Swap now
  public static let tokenSwapPromotionButton = Localization.tr("Localizable", "token_swap_promotion_button")
  /// Choose token you want to buy
  public static let tokensListAvailableToBuyHeader = Localization.tr("Localizable", "tokens_list_available_to_buy_header")
  /// Choose token you want to sell
  public static let tokensListAvailableToSellHeader = Localization.tr("Localizable", "tokens_list_available_to_sell_header")
  /// Choose token you want to swap
  public static let tokensListAvailableToSwapHeader = Localization.tr("Localizable", "tokens_list_available_to_swap_header")
  /// Market Trend 🔥
  public static let tokensListHotCryptoHeader = Localization.tr("Localizable", "tokens_list_hot_crypto_header")
  /// Unavailable to purchase
  public static let tokensListUnavailableToPurchaseHeader = Localization.tr("Localizable", "tokens_list_unavailable_to_purchase_header")
  /// Unavailable to sell
  public static let tokensListUnavailableToSellHeader = Localization.tr("Localizable", "tokens_list_unavailable_to_sell_header")
  /// Unavailable for swap from %@
  public static func tokensListUnavailableToSwapHeader(_ p1: Any) -> String {
    return Localization.tr("Localizable", "tokens_list_unavailable_to_swap_header", String(describing: p1))
  }
  /// Unavailable for swap
  public static let tokensListUnavailableToSwapSourceHeader = Localization.tr("Localizable", "tokens_list_unavailable_to_swap_source_header")
  /// contract: %@
  public static func transactionHistoryContractAddress(_ p1: Any) -> String {
    return Localization.tr("Localizable", "transaction_history_contract_address", String(describing: p1))
  }
  /// You don't have any transactions yet
  public static let transactionHistoryEmptyTransactions = Localization.tr("Localizable", "transaction_history_empty_transactions")
  /// Failed to load transaction history.\nClick on reload button to update the information.
  public static let transactionHistoryErrorFailedToLoad = Localization.tr("Localizable", "transaction_history_error_failed_to_load")
  /// Multiple addresses
  public static let transactionHistoryMultipleAddresses = Localization.tr("Localizable", "transaction_history_multiple_addresses")
  /// Transaction history is currently not supported for this blockchain. But don't worry, we're working on it! In the meantime you can check it in the explorer.
  public static let transactionHistoryNotSupportedDescription = Localization.tr("Localizable", "transaction_history_not_supported_description")
  /// Operation
  public static let transactionHistoryOperation = Localization.tr("Localizable", "transaction_history_operation")
  /// for: %@
  public static func transactionHistoryTransactionForAddress(_ p1: Any) -> String {
    return Localization.tr("Localizable", "transaction_history_transaction_for_address", String(describing: p1))
  }
  /// from: %@
  public static func transactionHistoryTransactionFromAddress(_ p1: Any) -> String {
    return Localization.tr("Localizable", "transaction_history_transaction_from_address", String(describing: p1))
  }
  /// to: %@
  public static func transactionHistoryTransactionToAddress(_ p1: Any) -> String {
    return Localization.tr("Localizable", "transaction_history_transaction_to_address", String(describing: p1))
  }
  /// validator: %@
  public static func transactionHistoryTransactionValidator(_ p1: Any) -> String {
    return Localization.tr("Localizable", "transaction_history_transaction_validator", String(describing: p1))
  }
  /// Notifications are enabled but won't work until you allow notifications in your device settings.
  public static let transactionNotificationsWarningDescription = Localization.tr("Localizable", "transaction_notifications_warning_description")
  /// Transaction Notifications
  public static let transactionNotificationsWarningTitle = Localization.tr("Localizable", "transaction_notifications_warning_title")
  /// Minimum %@
  public static func transferMinAmountError(_ p1: Any) -> String {
    return Localization.tr("Localizable", "transfer_min_amount_error", String(describing: p1))
  }
  /// The minimum transaction amount is %1$@.
  public static func transferNotificationInvalidMinimumTransactionAmountText(_ p1: Any) -> String {
    return Localization.tr("Localizable", "transfer_notification_invalid_minimum_transaction_amount_text", String(describing: p1))
  }
  /// Tron network fees for popular tokens can be higher. Staking TRX may help reduce transaction costs.
  public static let tronWillBeSendTokenFeeDescription = Localization.tr("Localizable", "tron_will_be_send_token_fee_description")
  /// Save on Tron network fees
  public static let tronWillBeSendTokenFeeTitle = Localization.tr("Localizable", "tron_will_be_send_token_fee_title")
  /// Try again
  public static let tryToLoadDataAgainButtonTitle = Localization.tr("Localizable", "try_to_load_data_again_button_title")
  /// You've scanned the same card. To create a twin wallet you need to scan the card with number %li
  public static func twinErrorSameCard(_ p1: Int) -> String {
    return Localization.tr("Localizable", "twin_error_same_card", p1)
  }
  /// You've scanned wrong twin card. Please try another one
  public static let twinErrorWrongTwin = Localization.tr("Localizable", "twin_error_wrong_twin")
  /// This one that you are holding in your hands and the other one with number %@.\n\nBoth cards can be used to extract funds from this wallet.
  public static func twinsOnboardingDescriptionFormat(_ p1: Any) -> String {
    return Localization.tr("Localizable", "twins_onboarding_description_format", String(describing: p1))
  }
  /// One wallet. Two cards.
  public static let twinsOnboardingSubtitle = Localization.tr("Localizable", "twins_onboarding_subtitle")
  /// Scan card #%@
  public static func twinsRecreateButtonFormat(_ p1: Any) -> String {
    return Localization.tr("Localizable", "twins_recreate_button_format", String(describing: p1))
  }
  /// Creating wallet
  public static let twinsRecreateTitleCreatingWallet = Localization.tr("Localizable", "twins_recreate_title_creating_wallet")
  /// Scan the #%@ twin card
  public static func twinsRecreateTitleFormat(_ p1: Any) -> String {
    return Localization.tr("Localizable", "twins_recreate_title_format", String(describing: p1))
  }
  /// Preparing card
  public static let twinsRecreateTitlePreparing = Localization.tr("Localizable", "twins_recreate_title_preparing")
  /// Tangem Twin
  public static let twinsRecreateToolbar = Localization.tr("Localizable", "twins_recreate_toolbar")
  /// This action is irreversible. You will not have access to the old wallet.
  public static let twinsRecreateWarning = Localization.tr("Localizable", "twins_recreate_warning")
  /// Tap the twin card with number %@ and do not remove until the end of the operation
  public static func twinsScanTwinWithNumber(_ p1: Any) -> String {
    return Localization.tr("Localizable", "twins_scan_twin_with_number", String(describing: p1))
  }
  /// Please try again later. If the issue persists, please contact support.
  public static let unexpectedErrorDescription = Localization.tr("Localizable", "unexpected_error_description")
  /// Something went wrong!
  public static let unexpectedErrorTitle = Localization.tr("Localizable", "unexpected_error_title")
  /// We've encountered an error. Error code: %@. Please contact our support.
  public static func universalError(_ p1: Any) -> String {
    return Localization.tr("Localizable", "universal_error", String(describing: p1))
  }
  /// Use %@ or scan a card/ring to have access to your wallet
  public static func unlockWalletDescriptionFull(_ p1: Any) -> String {
    return Localization.tr("Localizable", "unlock_wallet_description_full", String(describing: p1))
  }
  /// Connection failed: This dApp uses Wallet Connect version 1.0, which is not supported. Please ensure the dApp supports Wallet Connect version 2.0 to connect successfully.
  public static let unsupportedWcVersion = Localization.tr("Localizable", "unsupported_wc_version")
  /// Upgrade to hardware wallet
  public static let upgradeToHardwareWalletButtonTitle = Localization.tr("Localizable", "upgrade_to_hardware_wallet_button_title")
  /// Stay up to date with the latest features and news
  public static let userPushNotificationAgreementArgumentOne = Localization.tr("Localizable", "user_push_notification_agreement_argument_one")
  /// Real-time alerts for transactions, exchanges, and critical updates.
  public static let userPushNotificationAgreementArgumentOneSubtitle = Localization.tr("Localizable", "user_push_notification_agreement_argument_one_subtitle")
  /// Transaction Alerts
  public static let userPushNotificationAgreementArgumentOneTitle = Localization.tr("Localizable", "user_push_notification_agreement_argument_one_title")
  /// Get notified of incoming transactions
  public static let userPushNotificationAgreementArgumentThree = Localization.tr("Localizable", "user_push_notification_agreement_argument_three")
  /// Be the first to know about new promotions
  public static let userPushNotificationAgreementArgumentTwo = Localization.tr("Localizable", "user_push_notification_agreement_argument_two")
  /// Early access to fresh features and exclusive offers.
  public static let userPushNotificationAgreementArgumentTwoSubtitle = Localization.tr("Localizable", "user_push_notification_agreement_argument_two_subtitle")
  /// Feature and News Updates
  public static let userPushNotificationAgreementArgumentTwoTitle = Localization.tr("Localizable", "user_push_notification_agreement_argument_two_title")
  /// Would you like to use\nPush-notifications?
  public static let userPushNotificationAgreementHeader = Localization.tr("Localizable", "user_push_notification_agreement_header")
  /// Enable push notifications to receive alerts when funds arrive in your wallet.
  public static let userPushNotificationBannerSubtitle = Localization.tr("Localizable", "user_push_notification_banner_subtitle")
  /// Don't Miss a Transaction
  public static let userPushNotificationBannerTitle = Localization.tr("Localizable", "user_push_notification_banner_title")
  /// Add Wallet
  public static let userWalletListAddButton = Localization.tr("Localizable", "user_wallet_list_add_button")
  /// If you delete this wallet without a backup, you will permanently lose access to your funds.
  public static let userWalletListDeleteHwPrompt = Localization.tr("Localizable", "user_wallet_list_delete_hw_prompt")
  /// Are you sure you want to forget this wallet?
  public static let userWalletListDeletePrompt = Localization.tr("Localizable", "user_wallet_list_delete_prompt")
  /// This wallet has already been saved, you can add another one
  public static let userWalletListErrorWalletAlreadySaved = Localization.tr("Localizable", "user_wallet_list_error_wallet_already_saved")
  /// Wallet name
  public static let userWalletListRenamePopupPlaceholder = Localization.tr("Localizable", "user_wallet_list_rename_popup_placeholder")
  /// Rename wallet
  public static let userWalletListRenamePopupTitle = Localization.tr("Localizable", "user_wallet_list_rename_popup_title")
  /// Unlock all with %@
  public static func userWalletListUnlockAllWith(_ p1: Any) -> String {
    return Localization.tr("Localizable", "user_wallet_list_unlock_all_with", String(describing: p1))
  }
  /// AML verifired
  public static let visaBalanceLimitsDetailsAmlVerified = Localization.tr("Localizable", "visa_balance_limits_details_aml_verified")
  /// Available
  public static let visaBalanceLimitsDetailsAvailable = Localization.tr("Localizable", "visa_balance_limits_details_available")
  /// Blocked
  public static let visaBalanceLimitsDetailsBlocked = Localization.tr("Localizable", "visa_balance_limits_details_blocked")
  /// Debt
  public static let visaBalanceLimitsDetailsDebt = Localization.tr("Localizable", "visa_balance_limits_details_debt")
  /// Limits
  public static let visaBalanceLimitsDetailsLimits = Localization.tr("Localizable", "visa_balance_limits_details_limits")
  /// Other (no-otp)
  public static let visaBalanceLimitsDetailsNoOtpLimit = Localization.tr("Localizable", "visa_balance_limits_details_no_otp_limit")
  /// Single transaction
  public static let visaBalanceLimitsDetailsSingleTransaction = Localization.tr("Localizable", "visa_balance_limits_details_single_transaction")
  /// Total
  public static let visaBalanceLimitsDetailsTotal = Localization.tr("Localizable", "visa_balance_limits_details_total")
  /// Plural format key: "%#@format@"
  public static func visaLimitsAvailableForDaysTitle(_ p1: Int) -> String {
    return Localization.tr("Localizable", "visa_limits_available_for_days_title", p1)
  }
  /// Available balance is actual funds available, considering pending transactions, blocked amounts, and debit balance to prevent overdrafts.
  public static let visaMainAvailableBalanceAlertMessage = Localization.tr("Localizable", "visa_main_available_balance_alert_message")
  /// Available till %1$@
  public static func visaMainAvailableTillDate(_ p1: Any) -> String {
    return Localization.tr("Localizable", "visa_main_available_till_date", String(describing: p1))
  }
  /// Balances & Limits
  public static let visaMainBalancesAndLimits = Localization.tr("Localizable", "visa_main_balances_and_limits")
  /// Missing Payment account information. Please contact support
  public static let visaMainButtonAlertMissingPaymentAccountInfoMessage = Localization.tr("Localizable", "visa_main_button_alert_missing_payment_account_info_message")
  /// Unable to load information about token
  public static let visaMainButtonAlertMissingTokenInfo = Localization.tr("Localizable", "visa_main_button_alert_missing_token_info")
  /// Information is still loading, please wait
  public static let visaMainButtonAlertStillLoading = Localization.tr("Localizable", "visa_main_button_alert_still_loading")
  /// Limits are needed to control costs, improve security, manage risk. You can spend %1$@ during the period for card payments in shops and %2$@ for other transactions, e.g. subscriptions or debts.
  public static func visaMainLimitsAlertDescriptionMessage(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "visa_main_limits_alert_description_message", String(describing: p1), String(describing: p2))
  }
  /// The access code will be used manage your payment account and protect it from unauthorized access
  public static let visaOnboardingAccessCodeDescription = Localization.tr("Localizable", "visa_onboarding_access_code_description")
  /// Access Code
  public static let visaOnboardingAccessCodeNavigationTitle = Localization.tr("Localizable", "visa_onboarding_access_code_navigation_title")
  /// Account activation
  public static let visaOnboardingAccountActivationNavigationTitle = Localization.tr("Localizable", "visa_onboarding_account_activation_navigation_title")
  /// Please choose the wallet you started the registration process with to sign the transaction for creating your account on the Blockchain
  public static let visaOnboardingApproveWalletSelectorNotificationMessage = Localization.tr("Localizable", "visa_onboarding_approve_wallet_selector_notification_message")
  /// Cancel Activation
  public static let visaOnboardingCancelActivation = Localization.tr("Localizable", "visa_onboarding_cancel_activation")
  /// Are you sure you want to exit? You can continue later from where you left off.
  public static let visaOnboardingCloseAlertMessage = Localization.tr("Localizable", "visa_onboarding_close_alert_message")
  /// This won't take long. We're setting up your account.
  public static let visaOnboardingInProgressDescription = Localization.tr("Localizable", "visa_onboarding_in_progress_description")
  /// This won’t take long. We’re completing the activation.
  public static let visaOnboardingInProgressIssuerDescription = Localization.tr("Localizable", "visa_onboarding_in_progress_issuer_description")
  /// Getting everything ready!
  public static let visaOnboardingInProgressTitle = Localization.tr("Localizable", "visa_onboarding_in_progress_title")
  /// Other wallet
  public static let visaOnboardingOtherWallet = Localization.tr("Localizable", "visa_onboarding_other_wallet")
  /// Set up a 4-digit code.\nIt will be used for payments.
  public static let visaOnboardingPinCodeDescription = Localization.tr("Localizable", "visa_onboarding_pin_code_description")
  /// PIN code
  public static let visaOnboardingPinCodeNavigationTitle = Localization.tr("Localizable", "visa_onboarding_pin_code_navigation_title")
  /// Create PIN Code
  public static let visaOnboardingPinCodeTitle = Localization.tr("Localizable", "visa_onboarding_pin_code_title")
  /// PIN was not accepted. Try again or use a different code.
  public static let visaOnboardingPinNotAccepted = Localization.tr("Localizable", "visa_onboarding_pin_not_accepted")
  /// Invalid PIN: avoid sequences or repeats
  public static let visaOnboardingPinValidationErrorMessage = Localization.tr("Localizable", "visa_onboarding_pin_validation_error_message")
  /// You're good to go!
  public static let visaOnboardingSuccessScreenDescription = Localization.tr("Localizable", "visa_onboarding_success_screen_description")
  /// Prepare the Tangem card and tap to approve
  public static let visaOnboardingTangemApproveDescription = Localization.tr("Localizable", "visa_onboarding_tangem_approve_description")
  /// Prepare Tangem Wallet
  public static let visaOnboardingTangemApproveTitle = Localization.tr("Localizable", "visa_onboarding_tangem_approve_title")
  /// You will be able to complete your connection \n on the third-party web-site \n and back to the Tangem app
  public static let visaOnboardingWalletConnectDescription = Localization.tr("Localizable", "visa_onboarding_wallet_connect_description")
  /// Go to Website
  public static let visaOnboardingWalletConnectTitle = Localization.tr("Localizable", "visa_onboarding_wallet_connect_title")
  /// Wallet connection
  public static let visaOnboardingWalletConnectionNavigationTitle = Localization.tr("Localizable", "visa_onboarding_wallet_connection_navigation_title")
  /// Choose wallet
  public static let visaOnboardingWalletListHeader = Localization.tr("Localizable", "visa_onboarding_wallet_list_header")
  /// Continue Activation
  public static let visaOnboardingWelcomeBackButtonTitle = Localization.tr("Localizable", "visa_onboarding_welcome_back_button_title")
  /// Let's continue setting up your account.
  public static let visaOnboardingWelcomeBackDescription = Localization.tr("Localizable", "visa_onboarding_welcome_back_description")
  /// Welcome back!
  public static let visaOnboardingWelcomeBackTitle = Localization.tr("Localizable", "visa_onboarding_welcome_back_title")
  /// Start Activation
  public static let visaOnboardingWelcomeButtonTitle = Localization.tr("Localizable", "visa_onboarding_welcome_button_title")
  /// Follow the steps to set up your account.
  public static let visaOnboardingWelcomeDescription = Localization.tr("Localizable", "visa_onboarding_welcome_description")
  /// Welcome!
  public static let visaOnboardingWelcomeTitle = Localization.tr("Localizable", "visa_onboarding_welcome_title")
  /// Blockchain amount
  public static let visaTransactionDetailsBlockchainAmount = Localization.tr("Localizable", "visa_transaction_details_blockchain_amount")
  /// Currency code
  public static let visaTransactionDetailsCurrencyCode = Localization.tr("Localizable", "visa_transaction_details_currency_code")
  /// Date
  public static let visaTransactionDetailsDate = Localization.tr("Localizable", "visa_transaction_details_date")
  /// Error code
  public static let visaTransactionDetailsErrorCode = Localization.tr("Localizable", "visa_transaction_details_error_code")
  /// Transaction details
  public static let visaTransactionDetailsHeader = Localization.tr("Localizable", "visa_transaction_details_header")
  /// Merchant category code
  public static let visaTransactionDetailsMerchantCategoryCode = Localization.tr("Localizable", "visa_transaction_details_merchant_category_code")
  /// Merchant city
  public static let visaTransactionDetailsMerchantCity = Localization.tr("Localizable", "visa_transaction_details_merchant_city")
  /// Merchant country code
  public static let visaTransactionDetailsMerchantCountryCode = Localization.tr("Localizable", "visa_transaction_details_merchant_country_code")
  /// Merchant name
  public static let visaTransactionDetailsMerchantName = Localization.tr("Localizable", "visa_transaction_details_merchant_name")
  /// Request ID
  public static let visaTransactionDetailsRequestId = Localization.tr("Localizable", "visa_transaction_details_request_id")
  /// Status
  public static let visaTransactionDetailsStatus = Localization.tr("Localizable", "visa_transaction_details_status")
  /// Transaction
  public static let visaTransactionDetailsTitle = Localization.tr("Localizable", "visa_transaction_details_title")
  /// Transaction amount
  public static let visaTransactionDetailsTransactionAmount = Localization.tr("Localizable", "visa_transaction_details_transaction_amount")
  /// Transaction hash
  public static let visaTransactionDetailsTransactionHash = Localization.tr("Localizable", "visa_transaction_details_transaction_hash")
  /// Transaction request
  public static let visaTransactionDetailsTransactionRequest = Localization.tr("Localizable", "visa_transaction_details_transaction_request")
  /// Transaction status
  public static let visaTransactionDetailsTransactionStatus = Localization.tr("Localizable", "visa_transaction_details_transaction_status")
  /// Type
  public static let visaTransactionDetailsType = Localization.tr("Localizable", "visa_transaction_details_type")
  /// Dispute this transaction
  public static let visaTxDisputeButton = Localization.tr("Localizable", "visa_tx_dispute_button")
  /// Unlock
  public static let visaUnlockNotificationButton = Localization.tr("Localizable", "visa_unlock_notification_button")
  /// Scan your card to unlock access
  public static let visaUnlockNotificationSubtitle = Localization.tr("Localizable", "visa_unlock_notification_subtitle")
  /// Needed unlock
  public static let visaUnlockNotificationTitle = Localization.tr("Localizable", "visa_unlock_notification_title")
  /// Open device details
  public static let voiceOverOpenCardDetails = Localization.tr("Localizable", "voice_over_open_card_details")
  /// Scan QR code to open new WalletConnect session
  public static let voiceOverOpenNewWalletConnectSession = Localization.tr("Localizable", "voice_over_open_new_wallet_connect_session")
  /// Choose your wallet type
  public static let walletAddCommonTitle = Localization.tr("Localizable", "wallet_add_common_title")
  /// Scan your Tangem card or ring to restore it or import from another wallet.
  public static let walletAddHardwareDescription = Localization.tr("Localizable", "wallet_add_hardware_description")
  /// Create Hardware Wallet
  public static let walletAddHardwareInfoCreate = Localization.tr("Localizable", "wallet_add_hardware_info_create")
  /// Want to purchase a Tangem Wallet?
  public static let walletAddHardwarePurchase = Localization.tr("Localizable", "wallet_add_hardware_purchase")
  /// Import seed phrase
  public static let walletAddImportSeedPhrase = Localization.tr("Localizable", "wallet_add_import_seed_phrase")
  /// Restore your wallet on your phone or import from another app — convenient, but less secure than a Tangem card.
  public static let walletAddMobileDescription = Localization.tr("Localizable", "wallet_add_mobile_description")
  /// What to choose?
  public static let walletAddSupportTitle = Localization.tr("Localizable", "wallet_add_support_title")
  /// Scan card or ring
  public static let walletBalanceMissingDerivation = Localization.tr("Localizable", "wallet_balance_missing_derivation")
  /// This wallet has already been activated earlier.\nIf it was not done by you, please contact support.\nTangem never sells wallets along with pre-generated access codes.
  public static let walletBeenActivatedMessage = Localization.tr("Localizable", "wallet_been_activated_message")
  /// Failed to establish WalletConnect session: timeout error. Please, try again later.
  public static let walletConnectErrorTimeout = Localization.tr("Localizable", "wallet_connect_error_timeout")
  /// Multi-Part Transaction
  public static let walletConnectMultipleTransactions = Localization.tr("Localizable", "wallet_connect_multiple_transactions")
  /// To process successfully, your transaction will be split into multiple parts. You'll need to tap your card several times to complete it.
  public static let walletConnectMultipleTransactionsDescription = Localization.tr("Localizable", "wallet_connect_multiple_transactions_description")
  /// Paste from clipboard
  public static let walletConnectPasteFromClipboard = Localization.tr("Localizable", "wallet_connect_paste_from_clipboard")
  /// The transaction is being processed. Please tap your card multiple times to complete it.
  public static let walletConnectSendingMultipleExplanation = Localization.tr("Localizable", "wallet_connect_sending_multiple_explanation")
  /// Transaction in progress
  public static let walletConnectSendingMultipleTx = Localization.tr("Localizable", "wallet_connect_sending_multiple_tx")
  /// Connect to dApps
  public static let walletConnectSubtitle = Localization.tr("Localizable", "wallet_connect_subtitle")
  /// WalletConnect
  public static let walletConnectTitle = Localization.tr("Localizable", "wallet_connect_title")
  /// Create Tangem Wallet
  public static let walletCreateCommonTitle = Localization.tr("Localizable", "wallet_create_common_title")
  /// From %@
  public static func walletCreateHardwareBadge(_ p1: Any) -> String {
    return Localization.tr("Localizable", "wallet_create_hardware_badge", String(describing: p1))
  }
  /// Buy Tangem Wallet—a physical device that securely stores your private key offline.
  public static let walletCreateHardwareDescription = Localization.tr("Localizable", "wallet_create_hardware_description")
  /// Hardware Wallet
  public static let walletCreateHardwareTitle = Localization.tr("Localizable", "wallet_create_hardware_title")
  /// Create a secure wallet on your phone in seconds.
  public static let walletCreateMobileDescription = Localization.tr("Localizable", "wallet_create_mobile_description")
  /// Mobile Wallet
  public static let walletCreateMobileTitle = Localization.tr("Localizable", "wallet_create_mobile_title")
  /// What to pick
  public static let walletCreateNavInfoTitle = Localization.tr("Localizable", "wallet_create_nav_info_title")
  /// Using a Tangem Wallet already?
  public static let walletCreateScanQuestion = Localization.tr("Localizable", "wallet_create_scan_question")
  /// Scan now
  public static let walletCreateScanTitle = Localization.tr("Localizable", "wallet_create_scan_title")
  /// Pick a wallet setup method
  public static let walletCreateTitle = Localization.tr("Localizable", "wallet_create_title")
  /// Want to buy a Tangem Wallet?
  public static let walletImportBuyQuestion = Localization.tr("Localizable", "wallet_import_buy_question")
  /// Buy now
  public static let walletImportBuyTitle = Localization.tr("Localizable", "wallet_import_buy_title")
  /// Recover existing wallet via iCloud backup
  public static let walletImportIcloudDescription = Localization.tr("Localizable", "wallet_import_icloud_description")
  /// Import from iCloud
  public static let walletImportIcloudTitle = Localization.tr("Localizable", "wallet_import_icloud_title")
  /// Add existing wallet
  public static let walletImportNavtitle = Localization.tr("Localizable", "wallet_import_navtitle")
  /// Physical devices that securely store your private key offline.
  public static let walletImportScanDescription = Localization.tr("Localizable", "wallet_import_scan_description")
  /// Scan a Tangem Wallet
  public static let walletImportScanTitle = Localization.tr("Localizable", "wallet_import_scan_title")
  /// Import an existing wallet with your recovery phrase.
  public static let walletImportSeedDescription = Localization.tr("Localizable", "wallet_import_seed_description")
  /// Import wallet
  public static let walletImportSeedNavtitle = Localization.tr("Localizable", "wallet_import_seed_navtitle")
  /// Enter recovery phrase
  public static let walletImportSeedTitle = Localization.tr("Localizable", "wallet_import_seed_title")
  /// You successfully import up your wallet.
  public static let walletImportSuccessDescription = Localization.tr("Localizable", "wallet_import_success_description")
  /// Import wallet
  public static let walletImportSuccessNavtitle = Localization.tr("Localizable", "wallet_import_success_navtitle")
  /// Import completed
  public static let walletImportSuccessTitle = Localization.tr("Localizable", "wallet_import_success_title")
  /// Import wallet
  public static let walletImportTitle = Localization.tr("Localizable", "wallet_import_title")
  /// %@ Market Price
  public static func walletMarketplaceBlockTitle(_ p1: Any) -> String {
    return Localization.tr("Localizable", "wallet_marketplace_block_title", String(describing: p1))
  }
  /// last 24h
  public static let walletMarketpriceBlockUpdateTime = Localization.tr("Localizable", "wallet_marketprice_block_update_time")
  /// %@ network
  public static func walletNetworkGroupTitle(_ p1: Any) -> String {
    return Localization.tr("Localizable", "wallet_network_group_title", String(describing: p1))
  }
  /// Address was copied to clipboard
  public static let walletNotificationAddressCopied = Localization.tr("Localizable", "wallet_notification_address_copied")
  /// Get now with 10%% off
  public static let walletPromoBannerButtonTitle = Localization.tr("Localizable", "wallet_promo_banner_button_title")
  /// Access 13,000+ cryptocurrencies. Buy, sell, swap, and stake with a single tap.\nLink up to three cards for a backup.
  public static let walletPromoBannerDescription = Localization.tr("Localizable", "wallet_promo_banner_description")
  /// Discover Tangem Wallet
  public static let walletPromoBannerTitle = Localization.tr("Localizable", "wallet_promo_banner_title")
  /// This access code protects your wallet and is used to log in and sign transactions.
  public static let walletSettingsAccessCodeDescription = Localization.tr("Localizable", "wallet_settings_access_code_description")
  /// Set/Change access code
  public static let walletSettingsAccessCodeTitle = Localization.tr("Localizable", "wallet_settings_access_code_title")
  /// Change access code
  public static let walletSettingsChangeAccessCodeTitle = Localization.tr("Localizable", "wallet_settings_change_access_code_title")
  /// Get push notifications for incoming wallet transactions.
  public static let walletSettingsPushNotificationsDescription = Localization.tr("Localizable", "wallet_settings_push_notifications_description")
  /// Transaction notifications
  public static let walletSettingsPushNotificationsTitle = Localization.tr("Localizable", "wallet_settings_push_notifications_title")
  /// Set access code
  public static let walletSettingsSetAccessCodeTitle = Localization.tr("Localizable", "wallet_settings_set_access_code_title")
  /// Wallet settings
  public static let walletSettingsTitle = Localization.tr("Localizable", "wallet_settings_title")
  /// Tangem
  public static let walletTitle = Localization.tr("Localizable", "wallet_title")
  /// Use %@ or scan a card/ring to unlock access to your wallet
  public static func warningAccessDeniedMessage(_ p1: Any) -> String {
    return Localization.tr("Localizable", "warning_access_denied_message", String(describing: p1))
  }
  /// The permission-granting process is currently underway and will be completed shortly
  public static let warningApprovalInProgressMessage = Localization.tr("Localizable", "warning_approval_in_progress_message")
  /// Approval in Progress
  public static let warningApprovalInProgressTitle = Localization.tr("Localizable", "warning_approval_in_progress_title")
  /// Activation was not completed successfully. This may be due to an NFC issue or incorrect tapping. Please contact our Support team for assistance.
  public static let warningBackupErrorsMessage = Localization.tr("Localizable", "warning_backup_errors_message")
  /// On December 3, 2024, the BEP-2 network was disabled by decision of the network developers and is no longer supported
  public static let warningBeaconChainRetirementContent = Localization.tr("Localizable", "warning_beacon_chain_retirement_content")
  /// BNB Beacon Chain shut down
  public static let warningBeaconChainRetirementTitle = Localization.tr("Localizable", "warning_beacon_chain_retirement_title")
  /// Please deposit some %1$@ to cover the network fee
  public static func warningBlockedFundsForFeeMessage(_ p1: Any) -> String {
    return Localization.tr("Localizable", "warning_blocked_funds_for_fee_message", String(describing: p1))
  }
  /// Insufficient funds to cover the network fee
  public static let warningBlockedFundsForFeeTitle = Localization.tr("Localizable", "warning_blocked_funds_for_fee_title")
  /// Could be better
  public static let warningButtonCouldBeBetter = Localization.tr("Localizable", "warning_button_could_be_better")
  /// Ok, Got it!
  public static let warningButtonOk = Localization.tr("Localizable", "warning_button_ok")
  /// Really cool!
  public static let warningButtonReallyCool = Localization.tr("Localizable", "warning_button_really_cool")
  /// Refresh
  public static let warningButtonRefresh = Localization.tr("Localizable", "warning_button_refresh")
  /// Start migration
  public static let warningCloreMigrationButton = Localization.tr("Localizable", "warning_clore_migration_button")
  /// Copy
  public static let warningCloreMigrationCopyButton = Localization.tr("Localizable", "warning_clore_migration_copy_button")
  /// To keep access to your funds, start the migration according to the official Clore guidelines.
  public static let warningCloreMigrationDescription = Localization.tr("Localizable", "warning_clore_migration_description")
  /// Message signing is not supported for this network
  public static let warningCloreMigrationErrorSigningNotSupported = Localization.tr("Localizable", "warning_clore_migration_error_signing_not_supported")
  /// Unable to sign message. Please try again.
  public static let warningCloreMigrationErrorWalletManagerNotFound = Localization.tr("Localizable", "warning_clore_migration_error_wallet_manager_not_found")
  /// According to Clore’s official documentation, all coins received before December 21 will be migrated to Clore (ERC-20 token); coins received after that date will not. A transfer solution is coming — stay tuned.
  public static let warningCloreMigrationMessage = Localization.tr("Localizable", "warning_clore_migration_message")
  /// Message
  public static let warningCloreMigrationMessageLabel = Localization.tr("Localizable", "warning_clore_migration_message_label")
  /// Open Claim portal
  public static let warningCloreMigrationOpenPortalButton = Localization.tr("Localizable", "warning_clore_migration_open_portal_button")
  /// To continue using your Clore tokens, you must complete the token migration according to the information on the Claim Portal.
  public static let warningCloreMigrationSheetDescription = Localization.tr("Localizable", "warning_clore_migration_sheet_description")
  /// Clore Network Migration
  public static let warningCloreMigrationSheetTitle = Localization.tr("Localizable", "warning_clore_migration_sheet_title")
  /// Sign
  public static let warningCloreMigrationSignButton = Localization.tr("Localizable", "warning_clore_migration_sign_button")
  /// Signature
  public static let warningCloreMigrationSignatureLabel = Localization.tr("Localizable", "warning_clore_migration_signature_label")
  /// Clore Network Migration
  public static let warningCloreMigrationTitle = Localization.tr("Localizable", "warning_clore_migration_title")
  /// You are currently in the Demo mode
  public static let warningDemoModeMessage = Localization.tr("Localizable", "warning_demo_mode_message")
  /// Demo mode active
  public static let warningDemoModeTitle = Localization.tr("Localizable", "warning_demo_mode_title")
  /// The card you scanned is a developer card. Do not use it to create your wallet.
  public static let warningDeveloperCardMessage = Localization.tr("Localizable", "warning_developer_card_message")
  /// Not for users!
  public static let warningDeveloperCardTitle = Localization.tr("Localizable", "warning_developer_card_title")
  /// %1$@ network requires an Existential Deposit. If your account drops below %2$@, it will be deactivated, and any remaining funds will be destroyed.
  public static func warningExistentialDepositMessage(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "warning_existential_deposit_message", String(describing: p1), String(describing: p2))
  }
  /// Network requires Existential Deposit
  public static let warningExistentialDepositTitle = Localization.tr("Localizable", "warning_existential_deposit_title")
  /// Swap will be available after the %@ transaction is complete
  public static func warningExpressActiveTransactionMessage(_ p1: Any) -> String {
    return Localization.tr("Localizable", "warning_express_active_transaction_message", String(describing: p1))
  }
  /// You have active transaction
  public static let warningExpressActiveTransactionTitle = Localization.tr("Localizable", "warning_express_active_transaction_title")
  /// Swap approval is underway and will be completed shortly
  public static let warningExpressApprovalInProgressMessage = Localization.tr("Localizable", "warning_express_approval_in_progress_message")
  /// Approval in progress
  public static let warningExpressApprovalInProgressTitle = Localization.tr("Localizable", "warning_express_approval_in_progress_title")
  /// The minimum swapping amount is %1$@. Please ensure that the remaining balance after the swap will not be less than %2$@.
  public static func warningExpressDustMessage(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "warning_express_dust_message", String(describing: p1), String(describing: p2))
  }
  /// You don’t have any tokens in your portfolio that %@ can be swapped to. Please add another token to enable the exchange.
  public static func warningExpressNoExchangeableCoinsDescription(_ p1: Any) -> String {
    return Localization.tr("Localizable", "warning_express_no_exchangeable_coins_description", String(describing: p1))
  }
  /// No compatible tokens added
  public static let warningExpressNoExchangeableCoinsTitle = Localization.tr("Localizable", "warning_express_no_exchangeable_coins_title")
  /// To make a transaction you need to deposit some %1$@ %2$@
  public static func warningExpressNotEnoughFeeForTokenTxDescription(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "warning_express_not_enough_fee_for_token_tx_description", String(describing: p1), String(describing: p2))
  }
  /// Unable to cover %@ fee
  public static func warningExpressNotEnoughFeeForTokenTxTitle(_ p1: Any) -> String {
    return Localization.tr("Localizable", "warning_express_not_enough_fee_for_token_tx_title", String(describing: p1))
  }
  /// The amount to receive must be at least %@
  public static func warningExpressNotificationInvalidReserveAmountTitle(_ p1: Any) -> String {
    return Localization.tr("Localizable", "warning_express_notification_invalid_reserve_amount_title", String(describing: p1))
  }
  /// This may occur because the provider is currently unable to exchange your selected pair. Please wait a moment and try again. (Code %@)
  public static func warningExpressPairUnavailableMessage(_ p1: Any) -> String {
    return Localization.tr("Localizable", "warning_express_pair_unavailable_message", String(describing: p1))
  }
  /// Selected pair temporarily unavailable
  public static let warningExpressPairUnavailableTitle = Localization.tr("Localizable", "warning_express_pair_unavailable_title")
  /// Some providers are not authorized by the UK Financial Conduct Authority. You should avoid dealing with them.
  public static let warningExpressProvidersFcaWarningDescription = Localization.tr("Localizable", "warning_express_providers_fca_warning_description")
  /// FCA Warning List
  public static let warningExpressProvidersFcaWarningTitle = Localization.tr("Localizable", "warning_express_providers_fca_warning_title")
  /// Service temporarily unavailable
  public static let warningExpressRefreshRequiredTitle = Localization.tr("Localizable", "warning_express_refresh_required_title")
  /// The amount of tokens to be swapped must not exceed %@
  public static func warningExpressTooMaximumAmountTitle(_ p1: Any) -> String {
    return Localization.tr("Localizable", "warning_express_too_maximum_amount_title", String(describing: p1))
  }
  /// The amount to swap must be at least %@
  public static func warningExpressTooMinimalAmountTitle(_ p1: Any) -> String {
    return Localization.tr("Localizable", "warning_express_too_minimal_amount_title", String(describing: p1))
  }
  /// Please change the amount to swap
  public static let warningExpressWrongAmountDescription = Localization.tr("Localizable", "warning_express_wrong_amount_description")
  /// This card might be a production sample or counterfeit
  public static let warningFailedToVerifyCardMessage = Localization.tr("Localizable", "warning_failed_to_verify_card_message")
  /// Authenticity check failed
  public static let warningFailedToVerifyCardTitle = Localization.tr("Localizable", "warning_failed_to_verify_card_title")
  /// Associate
  public static let warningHederaMissingTokenAssociationButtonTitle = Localization.tr("Localizable", "warning_hedera_missing_token_association_button_title")
  /// This token must be associated with your Hedera account before you can receive it. Association fee ~%1$@ %2$@
  public static func warningHederaMissingTokenAssociationMessage(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "warning_hedera_missing_token_association_message", String(describing: p1), String(describing: p2))
  }
  /// This token must be associated with your Hedera account before you can receive it
  public static let warningHederaMissingTokenAssociationMessageBrief = Localization.tr("Localizable", "warning_hedera_missing_token_association_message_brief")
  /// Associate your token
  public static let warningHederaMissingTokenAssociationTitle = Localization.tr("Localizable", "warning_hedera_missing_token_association_title")
  /// Not enough %@. Top up your Hedera account to associate this token
  public static func warningHederaTokenAssociationNotEnoughHbarMessage(_ p1: Any) -> String {
    return Localization.tr("Localizable", "warning_hedera_token_association_not_enough_hbar_message", String(describing: p1))
  }
  /// Support for iOS %1$@ will end on %2$@. To continue receiving app updates and ensure full functionality, please update to the latest version of iOS.
  public static func warningIosDeprecationMessage(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "warning_ios_deprecation_message", String(describing: p1), String(describing: p2))
  }
  /// Are you sure you want to cancel the transaction? You will not be able to retry the transaction again
  public static let warningKaspaUnfinishedTokenTransactionDiscardMessage = Localization.tr("Localizable", "warning_kaspa_unfinished_token_transaction_discard_message")
  /// Your transaction with an amount of %1$@ %2$@ was not completed. You can try again to complete it.
  public static func warningKaspaUnfinishedTokenTransactionMessage(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "warning_kaspa_unfinished_token_transaction_message", String(describing: p1), String(describing: p2))
  }
  /// You have unfinished transaction
  public static let warningKaspaUnfinishedTokenTransactionTitle = Localization.tr("Localizable", "warning_kaspa_unfinished_token_transaction_title")
  /// Last update was %@
  public static func warningLastBalanceUpdatedTime(_ p1: Any) -> String {
    return Localization.tr("Localizable", "warning_last_balance_updated_time", String(describing: p1))
  }
  /// iPhone 7/7+ cannot sign transactions on this network. To complete this operation, please use a different phone.
  public static let warningLongTransactionMessage = Localization.tr("Localizable", "warning_long_transaction_message")
  /// Transaction signing unavailable
  public static let warningLongTransactionTitle = Localization.tr("Localizable", "warning_long_transaction_title")
  /// Only %@ signatures are left on this card. You must withdraw all of your funds.
  public static func warningLowSignaturesMessage(_ p1: Any) -> String {
    return Localization.tr("Localizable", "warning_low_signatures_message", String(describing: p1))
  }
  /// Low signature count
  public static let warningLowSignaturesTitle = Localization.tr("Localizable", "warning_low_signatures_title")
  /// Tokens on different networks can have different addresses. Double-check that your address matches the network when you transfer funds.
  public static let warningManageTokensLegacyDerivationMessage = Localization.tr("Localizable", "warning_manage_tokens_legacy_derivation_message")
  /// MATIC is being migrated to POL. However, there is no deadline set and MATIC isn't being deprecated yet. You can safely continue using MATIC token or swap it for POL.
  public static let warningMaticMigrationMessage = Localization.tr("Localizable", "warning_matic_migration_message")
  /// MATIC to POL Migration
  public static let warningMaticMigrationTitle = Localization.tr("Localizable", "warning_matic_migration_title")
  /// Plural format key: "%#@format@"
  public static func warningMissingDerivationMessage(_ p1: Int) -> String {
    return Localization.tr("Localizable", "warning_missing_derivation_message", p1)
  }
  /// Some addresses are missing
  public static let warningMissingDerivationTitle = Localization.tr("Localizable", "warning_missing_derivation_title")
  /// The network is currently unreachable. Please try again later.
  public static let warningNetworkUnreachableMessage = Localization.tr("Localizable", "warning_network_unreachable_message")
  /// Network is unreachable
  public static let warningNetworkUnreachableTitle = Localization.tr("Localizable", "warning_network_unreachable_title")
  /// Top up your wallet
  public static let warningNoAccountTitle = Localization.tr("Localizable", "warning_no_account_title")
  /// Your wallet isn't backed up yet. Back it up now to protect your assets.
  public static let warningNoBackupMessage = Localization.tr("Localizable", "warning_no_backup_message")
  /// Missing backup
  public static let warningNoBackupTitle = Localization.tr("Localizable", "warning_no_backup_title")
  /// This card has been previously used for transactions. If received from an untrusted source, consider withdrawing all funds. If it's your card, no action is required.
  public static let warningNumberOfSignedHashesIncorrectMessage = Localization.tr("Localizable", "warning_number_of_signed_hashes_incorrect_message")
  /// Card has already signed transactions
  public static let warningNumberOfSignedHashesIncorrectTitle = Localization.tr("Localizable", "warning_number_of_signed_hashes_incorrect_title")
  /// Funds in Tangem devices issued before September 2019 cannot be retrieved on iPhones due to iOS restrictions. Please use an Android phone for retrieval. Devices issued after September 2019 work correctly on both OS.
  public static let warningOldCardMessage = Localization.tr("Localizable", "warning_old_card_message")
  /// iOS restriction for older cards
  public static let warningOldCardTitle = Localization.tr("Localizable", "warning_old_card_title")
  /// Some iPhone 7/7+ models may have NFC issues during certain operations.
  public static let warningOldDeviceOldCardMessage = Localization.tr("Localizable", "warning_old_device_old_card_message")
  /// Device incompatibility detected
  public static let warningOldDeviceOldCardTitle = Localization.tr("Localizable", "warning_old_device_old_card_title")
  /// Your review keeps us motivated to make Tangem Wallet even better
  public static let warningRateAppMessage = Localization.tr("Localizable", "warning_rate_app_message")
  /// Enjoying Tangem?
  public static let warningRateAppTitle = Localization.tr("Localizable", "warning_rate_app_title")
  /// You must associate your token before receiving tokens
  public static let warningReceiveBlockedHederaTokenAssociationRequiredMessage = Localization.tr("Localizable", "warning_receive_blocked_hedera_token_association_required_message")
  /// You must open trustline for your token before receiving it
  public static let warningReceiveBlockedTokenTrustlineRequiredMessage = Localization.tr("Localizable", "warning_receive_blocked_token_trustline_required_message")
  /// Network rent fee required
  public static let warningRentFeeTitle = Localization.tr("Localizable", "warning_rent_fee_title")
  /// Action required
  public static let warningSeedphraseActionRequiredTitle = Localization.tr("Localizable", "warning_seedphrase_action_required_title")
  /// Did you contact support via the app within 7 days of creating your wallet? If yes, or if you're unsure, click 'Yes' and follow the instructions.
  public static let warningSeedphraseContactedSupport = Localization.tr("Localizable", "warning_seedphrase_contacted_support")
  /// Thank you! All set! No further actions required.
  public static let warningSeedphraseIssueAnswerNo = Localization.tr("Localizable", "warning_seedphrase_issue_answer_no")
  /// You will now be redirected to the official Tangem website. Please read and follow instructions there.
  public static let warningSeedphraseIssueAnswerYes = Localization.tr("Localizable", "warning_seedphrase_issue_answer_yes")
  /// Have you ever contacted the Tangem support team directly through this application?
  public static let warningSeedphraseIssueMessage = Localization.tr("Localizable", "warning_seedphrase_issue_message")
  /// Mandatory security update
  public static let warningSeedphraseIssueTitle = Localization.tr("Localizable", "warning_seedphrase_issue_title")
  /// %1$@ is an asset in the %2$@ network. To make a %3$@ transaction, you must deposit some %4$@ (%5$@) to cover the network fee.
  public static func warningSendBlockedFundsForFeeMessage(_ p1: Any, _ p2: Any, _ p3: Any, _ p4: Any, _ p5: Any) -> String {
    return Localization.tr("Localizable", "warning_send_blocked_funds_for_fee_message", String(describing: p1), String(describing: p2), String(describing: p3), String(describing: p4), String(describing: p5))
  }
  /// Insufficient %1$@ to cover network fee
  public static func warningSendBlockedFundsForFeeTitle(_ p1: Any) -> String {
    return Localization.tr("Localizable", "warning_send_blocked_funds_for_fee_title", String(describing: p1))
  }
  /// Solana network charges a rent of %1$@ every 2 days. Accounts that can't afford the rent are purged from the network. Deposit your account with more than %2$@ to use it for free.
  public static func warningSolanaRentFeeMessage(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "warning_solana_rent_fee_message", String(describing: p1), String(describing: p2))
  }
  /// Swipe down to refresh or try again later.
  public static let warningSomeNetworksUnreachableMessage = Localization.tr("Localizable", "warning_some_networks_unreachable_message")
  /// Some networks are unreachable
  public static let warningSomeNetworksUnreachableTitle = Localization.tr("Localizable", "warning_some_networks_unreachable_title")
  /// Some token balances could not be updated
  public static let warningSomeTokenBalancesNotUpdated = Localization.tr("Localizable", "warning_some_token_balances_not_updated")
  /// Not enough %@. Top up your XLM account to open trustline.
  public static func warningStellarTokenTrustlineNotEnoughXlm(_ p1: Any) -> String {
    return Localization.tr("Localizable", "warning_stellar_token_trustline_not_enough_xlm", String(describing: p1))
  }
  /// System update required
  public static let warningSystemDeprecationTitle = Localization.tr("Localizable", "warning_system_deprecation_title")
  /// Support for your version of the operating system will end on %@. To receive future app updates you must update it to the latest version.
  public static func warningSystemDeprecationWithDateMessage(_ p1: Any) -> String {
    return Localization.tr("Localizable", "warning_system_deprecation_with_date_message", String(describing: p1))
  }
  /// Tangem recommends installing the latest iOS update for stable and safe operation
  public static let warningSystemUpdateMessage = Localization.tr("Localizable", "warning_system_update_message")
  /// System update available
  public static let warningSystemUpdateTitle = Localization.tr("Localizable", "warning_system_update_title")
  /// This is a Testnet card. It cannot process transactions and should only be used for testing and development purposes.
  public static let warningTestnetCardMessage = Localization.tr("Localizable", "warning_testnet_card_message")
  /// For testing purposes only
  public static let warningTestnetCardTitle = Localization.tr("Localizable", "warning_testnet_card_title")
  /// Not enough %1$@. Top up your %2$@ account to associate this token
  public static func warningTokenRequiredMinCoinReserve(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "warning_token_required_min_coin_reserve", String(describing: p1), String(describing: p2))
  }
  /// Enable Trustline
  public static let warningTokenTrustlineButtonTitle = Localization.tr("Localizable", "warning_token_trustline_button_title")
  /// A Trustline must be enabled to receive this token. The network requires a %1$@ %2$@ reserve.
  public static func warningTokenTrustlineSubtitle(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "warning_token_trustline_subtitle", String(describing: p1), String(describing: p2))
  }
  /// Trustline Required
  public static let warningTokenTrustlineTitle = Localization.tr("Localizable", "warning_token_trustline_title")
  /// The required network %@ is not added to your portfolio. Add it first, then proceed with the connection.
  public static func wcAlertAddNetworkToPortfolioDescription(_ p1: Any) -> String {
    return Localization.tr("Localizable", "wc_alert_add_network_to_portfolio_description", String(describing: p1))
  }
  /// Add network to portfolio
  public static let wcAlertAddNetworkToPortfolioTitle = Localization.tr("Localizable", "wc_alert_add_network_to_portfolio_title")
  /// Malicious domain
  public static let wcAlertAuditMaliciousDomain = Localization.tr("Localizable", "wc_alert_audit_malicious_domain")
  /// Unknown domain
  public static let wcAlertAuditUnknownDomain = Localization.tr("Localizable", "wc_alert_audit_unknown_domain")
  /// Connect anyway
  public static let wcAlertConnectAnyway = Localization.tr("Localizable", "wc_alert_connect_anyway")
  /// Timeout error. Please, try again later.
  public static let wcAlertConnectionTimeoutDescription = Localization.tr("Localizable", "wc_alert_connection_timeout_description")
  /// Failed to establish WalletConnect
  public static let wcAlertConnectionTimeoutTitle = Localization.tr("Localizable", "wc_alert_connection_timeout_title")
  /// This domain cannot be verified. Check the request carefully approving.
  public static let wcAlertDomainIssuesDescription = Localization.tr("Localizable", "wc_alert_domain_issues_description")
  /// To continue, please reconnect your dApp session with the required network %@.
  public static func wcAlertNetworkNotConnectedDescription(_ p1: Any) -> String {
    return Localization.tr("Localizable", "wc_alert_network_not_connected_description", String(describing: p1))
  }
  /// Network not connected
  public static let wcAlertNetworkNotConnectedTitle = Localization.tr("Localizable", "wc_alert_network_not_connected_title")
  /// Check your network connection
  public static let wcAlertRequestTimeoutDescription = Localization.tr("Localizable", "wc_alert_request_timeout_description")
  /// Request timeout
  public static let wcAlertRequestTimeoutTitle = Localization.tr("Localizable", "wc_alert_request_timeout_title")
  /// Please return to your browser and reconnect via WalletConnect.
  public static let wcAlertSessionDisconnectedDescription = Localization.tr("Localizable", "wc_alert_session_disconnected_description")
  /// Wallet Connect session was disconnected
  public static let wcAlertSessionDisconnectedTitle = Localization.tr("Localizable", "wc_alert_session_disconnected_title")
  /// Sign anyway
  public static let wcAlertSignAnyway = Localization.tr("Localizable", "wc_alert_sign_anyway")
  /// Error code: %@. If the problem persists — feel free to contact our support.
  public static func wcAlertUnknownErrorDescription(_ p1: Any) -> String {
    return Localization.tr("Localizable", "wc_alert_unknown_error_description", String(describing: p1))
  }
  /// If the problem persists — feel free to contact our support.
  public static let wcAlertUnknownErrorDescriptionNoErrorCode = Localization.tr("Localizable", "wc_alert_unknown_error_description_no_error_code")
  /// We've encountered unknown error
  public static let wcAlertUnknownErrorTitle = Localization.tr("Localizable", "wc_alert_unknown_error_title")
  /// Tangem Wallet currently doesn’t support %@.
  public static func wcAlertUnsupportedDappsDescription(_ p1: Any) -> String {
    return Localization.tr("Localizable", "wc_alert_unsupported_dapps_description", String(describing: p1))
  }
  /// Unsupported dApp
  public static let wcAlertUnsupportedDappsTitle = Localization.tr("Localizable", "wc_alert_unsupported_dapps_title")
  /// Error code: 8 005. If the problem persists — feel free to contact our support.
  public static let wcAlertUnsupportedMethodDescription = Localization.tr("Localizable", "wc_alert_unsupported_method_description")
  /// We've encountered unknown error
  public static let wcAlertUnsupportedMethodTitle = Localization.tr("Localizable", "wc_alert_unsupported_method_title")
  /// This network %@ is not supported by Tangem Wallet and cannot be connected.
  public static func wcAlertUnsupportedNetworkDescription(_ p1: Any) -> String {
    return Localization.tr("Localizable", "wc_alert_unsupported_network_description", String(describing: p1))
  }
  /// Unsupported network
  public static let wcAlertUnsupportedNetworkTitle = Localization.tr("Localizable", "wc_alert_unsupported_network_title")
  /// Tangem does not currently support a required network by %@.
  public static func wcAlertUnsupportedNetworksDescription(_ p1: Any) -> String {
    return Localization.tr("Localizable", "wc_alert_unsupported_networks_description", String(describing: p1))
  }
  /// Unsupported networks
  public static let wcAlertUnsupportedNetworksTitle = Localization.tr("Localizable", "wc_alert_unsupported_networks_title")
  /// This domain has passed verification checks and is considered safe, reputable, and free from known threats or suspicious activity.
  public static let wcAlertVerifiedDomainDescription = Localization.tr("Localizable", "wc_alert_verified_domain_description")
  /// Verified domain
  public static let wcAlertVerifiedDomainTitle = Localization.tr("Localizable", "wc_alert_verified_domain_title")
  /// Wrong card or ring selected in the App
  public static let wcAlertWrongCardDescription = Localization.tr("Localizable", "wc_alert_wrong_card_description")
  /// We've got some kind of problem
  public static let wcAlertWrongCardTitle = Localization.tr("Localizable", "wc_alert_wrong_card_title")
  /// All dApps disconnected
  public static let wcAllDappsDisconnected = Localization.tr("Localizable", "wc_all_dapps_disconnected")
  /// Allow to spend
  public static let wcAllowToSpend = Localization.tr("Localizable", "wc_allow_to_spend")
  /// By approving, you allow dApp or Smart contract to use tokens in future transactions.
  public static let wcApproveDescription = Localization.tr("Localizable", "wc_approve_description")
  /// Address
  public static let wcCommonAddress = Localization.tr("Localizable", "wc_common_address")
  /// Connect
  public static let wcCommonConnect = Localization.tr("Localizable", "wc_common_connect")
  /// Loading
  public static let wcCommonLoading = Localization.tr("Localizable", "wc_common_loading")
  /// Network
  public static let wcCommonNetwork = Localization.tr("Localizable", "wc_common_network")
  /// Networks
  public static let wcCommonNetworks = Localization.tr("Localizable", "wc_common_networks")
  /// Unlimited
  public static let wcCommonUnlimited = Localization.tr("Localizable", "wc_common_unlimited")
  /// Wallet
  public static let wcCommonWallet = Localization.tr("Localizable", "wc_common_wallet")
  /// Connected App
  public static let wcConnectedAppTitle = Localization.tr("Localizable", "wc_connected_app_title")
  /// Connected networks
  public static let wcConnectedNetworks = Localization.tr("Localizable", "wc_connected_networks")
  /// Connected to %1$@
  public static func wcConnectedTo(_ p1: Any) -> String {
    return Localization.tr("Localizable", "wc_connected_to", String(describing: p1))
  }
  /// View your wallet balance and activity
  public static let wcConnectionReqeustCanViewBalance = Localization.tr("Localizable", "wc_connection_reqeust_can_view_balance")
  /// Sign transactions without your notice
  public static let wcConnectionReqeustCantSign = Localization.tr("Localizable", "wc_connection_reqeust_cant_sign")
  /// Request approval for transactions
  public static let wcConnectionReqeustRequestApproval = Localization.tr("Localizable", "wc_connection_reqeust_request_approval")
  /// Will not be able to
  public static let wcConnectionReqeustWillNot = Localization.tr("Localizable", "wc_connection_reqeust_will_not")
  /// Would like to
  public static let wcConnectionReqeustWouldLike = Localization.tr("Localizable", "wc_connection_reqeust_would_like")
  /// Connection request
  public static let wcConnectionRequest = Localization.tr("Localizable", "wc_connection_request")
  /// Connections
  public static let wcConnections = Localization.tr("Localizable", "wc_connections")
  /// Contents
  public static let wcContents = Localization.tr("Localizable", "wc_contents")
  /// Copy data
  public static let wcCopyDataButtonText = Localization.tr("Localizable", "wc_copy_data_button_text")
  /// Custom allowance
  public static let wcCustomAllowanceTitle = Localization.tr("Localizable", "wc_custom_allowance_title")
  /// dApp disconnected
  public static let wcDappDisconnected = Localization.tr("Localizable", "wc_dapp_disconnected")
  /// Disconnect all
  public static let wcDisconnectAll = Localization.tr("Localizable", "wc_disconnect_all")
  /// All dApp sessions will be disconnected. Your wallet will no longer be linked to any dApps.
  public static let wcDisconnectAllAlertDesc = Localization.tr("Localizable", "wc_disconnect_all_alert_desc")
  /// Disconect All dApps
  public static let wcDisconnectAllAlertTitle = Localization.tr("Localizable", "wc_disconnect_all_alert_title")
  /// Try pairing again with a fresh URI
  public static let wcErrorsInvalidDomainSubtitle = Localization.tr("Localizable", "wc_errors_invalid_domain_subtitle")
  /// Invalid dApp domain
  public static let wcErrorsInvalidDomainTitle = Localization.tr("Localizable", "wc_errors_invalid_domain_title")
  /// %@ does not specify any blockchains — neither required nor optional.\nPlease ensure you used the correct URI
  public static func wcErrorsNoBlockchainsSubtitle(_ p1: Any) -> String {
    return Localization.tr("Localizable", "wc_errors_no_blockchains_subtitle", String(describing: p1))
  }
  /// No networks
  public static let wcErrorsNoBlockchainsTitle = Localization.tr("Localizable", "wc_errors_no_blockchains_title")
  /// Please, generate a new URI and attempt connecting again
  public static let wcErrorsProposalExpiredSubtitle = Localization.tr("Localizable", "wc_errors_proposal_expired_subtitle")
  /// Connection proposal expired
  public static let wcErrorsProposalExpiredTitle = Localization.tr("Localizable", "wc_errors_proposal_expired_title")
  /// Estimated wallet changes
  public static let wcEstimatedWalletChanges = Localization.tr("Localizable", "wc_estimated_wallet_changes")
  /// The transaction couldn't be simulated. Please proceed with caution.
  public static let wcEstimatedWalletChangesNotSimulated = Localization.tr("Localizable", "wc_estimated_wallet_changes_not_simulated")
  /// Estimation is not supported for %@
  public static func wcEstimationIsNotSupported(_ p1: Any) -> String {
    return Localization.tr("Localizable", "wc_estimation_is_not_supported", String(describing: p1))
  }
  /// Suggested by %@
  public static func wcFeeSuggested(_ p1: Any) -> String {
    return Localization.tr("Localizable", "wc_fee_suggested", String(describing: p1))
  }
  /// Top up your balance to cover the network fee
  public static let wcInsufficientWarningSubtitle = Localization.tr("Localizable", "wc_insufficient_warning_subtitle")
  /// Insufficient %1$@
  public static func wcInsufficientWarningTitle(_ p1: Any) -> String {
    return Localization.tr("Localizable", "wc_insufficient_warning_title", String(describing: p1))
  }
  /// Malicious transaction
  public static let wcMaliciousTransaction = Localization.tr("Localizable", "wc_malicious_transaction")
  /// This transaction has been flagged as malicious. It may result in loss of funds
  public static let wcMaliciousTxAlertDefaultDescription = Localization.tr("Localizable", "wc_malicious_tx_alert_default_description")
  /// Add the %@ network to your portfolio for this wallet
  public static func wcMissingRequiredNetworkDescription(_ p1: Any) -> String {
    return Localization.tr("Localizable", "wc_missing_required_network_description", String(describing: p1))
  }
  /// The wallet has no required networks
  public static let wcMissingRequiredNetworkTitle = Localization.tr("Localizable", "wc_missing_required_network_title")
  /// New connection
  public static let wcNewConnection = Localization.tr("Localizable", "wc_new_connection")
  /// Connect your wallet to different dApps
  public static let wcNoSessionsDesc = Localization.tr("Localizable", "wc_no_sessions_desc")
  /// No sessions
  public static let wcNoSessionsTitle = Localization.tr("Localizable", "wc_no_sessions_title")
  /// No wallet changes detected
  public static let wcNoWalletChangesDetected = Localization.tr("Localizable", "wc_no_wallet_changes_detected")
  /// Potential risks or malicious behavior have been detected. Connecting or signing transactions may lead to loss of funds.
  public static let wcNotificationSecurityRiskSubtitle = Localization.tr("Localizable", "wc_notification_security_risk_subtitle")
  /// Known security risk
  public static let wcNotificationSecurityRiskTitle = Localization.tr("Localizable", "wc_notification_security_risk_title")
  /// Open the Web3 app and choose the WalletConnect option.
  public static let wcQrScanHint = Localization.tr("Localizable", "wc_qr_scan_hint")
  /// Request from
  public static let wcRequestFrom = Localization.tr("Localizable", "wc_request_from")
  /// Sign anyway
  public static let wcSendAnyway = Localization.tr("Localizable", "wc_send_anyway")
  /// Signature Type
  public static let wcSignatureType = Localization.tr("Localizable", "wc_signature_type")
  /// At least one network is required for dApp connection
  public static let wcSpecifyNetworksSubtitle = Localization.tr("Localizable", "wc_specify_networks_subtitle")
  /// Specify selected networks
  public static let wcSpecifyNetworksTitle = Localization.tr("Localizable", "wc_specify_networks_title")
  /// Successfully signed
  public static let wcSuccessfullySigned = Localization.tr("Localizable", "wc_successfully_signed")
  /// WalletConnect
  public static let wcTransactionFlowTitle = Localization.tr("Localizable", "wc_transaction_flow_title")
  /// To
  public static let wcTransactionInfoToTitle = Localization.tr("Localizable", "wc_transaction_info_to_title")
  /// Transaction request
  public static let wcTransactionRequest = Localization.tr("Localizable", "wc_transaction_request")
  /// Transaction request
  public static let wcTransactionRequestTitle = Localization.tr("Localizable", "wc_transaction_request_title")
  /// We couldn’t confirm if this transaction will succeed. Proceed with caution.
  public static let wcUnknownTxNotificationDescription = Localization.tr("Localizable", "wc_unknown_tx_notification_description")
  /// Unknown transaction
  public static let wcUnknownTxNotificationTitle = Localization.tr("Localizable", "wc_unknown_tx_notification_title")
  /// Unlimited Amount
  public static let wcUnlimitedAmount = Localization.tr("Localizable", "wc_unlimited_amount")
  /// Ensure that each pairing attempt uses a fresh and unique URI
  public static let wcUriAlreadyUsedDescription = Localization.tr("Localizable", "wc_uri_already_used_description")
  /// URI already used
  public static let wcUriAlreadyUsedTitle = Localization.tr("Localizable", "wc_uri_already_used_title")
  /// WalletConnect
  public static let wcWalletConnect = Localization.tr("Localizable", "wc_wallet_connect")
  /// Suspicious transaction
  public static let wcWarningTransaction = Localization.tr("Localizable", "wc_warning_transaction")
  /// This transaction appears unusual or risky. Please review it carefully before signing.
  public static let wcWarningTxAlertDefaultDescription = Localization.tr("Localizable", "wc_warning_tx_alert_default_description")
  /// Already have Tangem Wallet?
  public static let welcomeCreateWalletAlreadyHave = Localization.tr("Localizable", "welcome_create_wallet_already_have")
  /// Thousands of assets
  public static let welcomeCreateWalletFeatureAssets = Localization.tr("Localizable", "welcome_create_wallet_feature_assets")
  /// Top-tier hardware wallet
  public static let welcomeCreateWalletFeatureClass = Localization.tr("Localizable", "welcome_create_wallet_feature_class")
  /// Fast delivery
  public static let welcomeCreateWalletFeatureDelivery = Localization.tr("Localizable", "welcome_create_wallet_feature_delivery")
  /// Start in one tap
  public static let welcomeCreateWalletFeatureOneTap = Localization.tr("Localizable", "welcome_create_wallet_feature_one_tap")
  /// Seamless and secure
  public static let welcomeCreateWalletFeatureSeamless = Localization.tr("Localizable", "welcome_create_wallet_feature_seamless")
  /// No seed phrase
  public static let welcomeCreateWalletFeatureSeedphrase = Localization.tr("Localizable", "welcome_create_wallet_feature_seedphrase")
  /// Simple to use
  public static let welcomeCreateWalletFeatureUse = Localization.tr("Localizable", "welcome_create_wallet_feature_use")
  /// Create a hardware wallet with Tangem. Slim as a bank card, secure as a bank vault.
  public static let welcomeCreateWalletHardwareDescription = Localization.tr("Localizable", "welcome_create_wallet_hardware_description")
  /// Create or import a software wallet
  public static let welcomeCreateWalletMobileDescription = Localization.tr("Localizable", "welcome_create_wallet_mobile_description")
  /// Create or import a software wallet on your phone.
  public static let welcomeCreateWalletMobileDescriptionFull = Localization.tr("Localizable", "welcome_create_wallet_mobile_description_full")
  /// Start with Mobile Wallet
  public static let welcomeCreateWalletMobileTitle = Localization.tr("Localizable", "welcome_create_wallet_mobile_title")
  /// Other methods
  public static let welcomeCreateWalletOtherMethod = Localization.tr("Localizable", "welcome_create_wallet_other_method")
  /// Use a Tangem hardware wallet
  public static let welcomeCreateWalletUseHardwareDescription = Localization.tr("Localizable", "welcome_create_wallet_use_hardware_description")
  /// Learn more & buy
  public static let welcomeCreateWalletUseHardwareTitle = Localization.tr("Localizable", "welcome_create_wallet_use_hardware_title")
  /// Discard
  public static let welcomeInterruptedBackupAlertDiscard = Localization.tr("Localizable", "welcome_interrupted_backup_alert_discard")
  /// Your backup was interrupted. Do you want to resume?
  public static let welcomeInterruptedBackupAlertMessage = Localization.tr("Localizable", "welcome_interrupted_backup_alert_message")
  /// Yes, resume
  public static let welcomeInterruptedBackupAlertResume = Localization.tr("Localizable", "welcome_interrupted_backup_alert_resume")
  /// Discard
  public static let welcomeInterruptedBackupDiscardDiscard = Localization.tr("Localizable", "welcome_interrupted_backup_discard_discard")
  /// If you discard the backup now, you will have to reset the devices to factory settings to start over again
  public static let welcomeInterruptedBackupDiscardMessage = Localization.tr("Localizable", "welcome_interrupted_backup_discard_message")
  /// Resume backup
  public static let welcomeInterruptedBackupDiscardResume = Localization.tr("Localizable", "welcome_interrupted_backup_discard_resume")
  /// This is an irreversible action
  public static let welcomeInterruptedBackupDiscardTitle = Localization.tr("Localizable", "welcome_interrupted_backup_discard_title")
  /// Log in with %@
  public static func welcomeUnlock(_ p1: Any) -> String {
    return Localization.tr("Localizable", "welcome_unlock", String(describing: p1))
  }
  /// Scan card or ring
  public static let welcomeUnlockCard = Localization.tr("Localizable", "welcome_unlock_card")
  /// Use %@ or scan a card or ring to access the app
  public static func welcomeUnlockDescription(_ p1: Any) -> String {
    return Localization.tr("Localizable", "welcome_unlock_description", String(describing: p1))
  }
  /// Welcome back!
  public static let welcomeUnlockTitle = Localization.tr("Localizable", "welcome_unlock_title")
  /// No, send all
  public static let xtzWithdrawalMessageIgnore = Localization.tr("Localizable", "xtz_withdrawal_message_ignore")
  /// Reduce by %@ XTZ
  public static func xtzWithdrawalMessageReduce(_ p1: Any) -> String {
    return Localization.tr("Localizable", "xtz_withdrawal_message_reduce", String(describing: p1))
  }
  /// To avoid paying an increased commission the next time you top up your wallet, reduce the amount by %@ XTZ
  public static func xtzWithdrawalMessageWarning(_ p1: Any) -> String {
    return Localization.tr("Localizable", "xtz_withdrawal_message_warning", String(describing: p1))
  }
  /// When Yield Mode is active, all future top-ups to this address will be supplied to Aave. You can still manage your funds freely.
  public static let yieldModuleAlertDescription = Localization.tr("Localizable", "yield_module_alert_description")
  /// Your %@ is supplied to Aave
  public static func yieldModuleAlertTitle(_ p1: Any) -> String {
    return Localization.tr("Localizable", "yield_module_alert_title", String(describing: p1))
  }
  /// Supplying %1$@ %2$@ to Aave
  public static func yieldModuleAmountNotTransferedToAaveTitle(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "yield_module_amount_not_transfered_to_aave_title", String(describing: p1), String(describing: p2))
  }
  /// Approve
  public static let yieldModuleApproveNeededNotificationCta = Localization.tr("Localizable", "yield_module_approve_needed_notification_cta")
  /// Your token's approval has been revoked. Grant it again to resume the service's functionality.
  public static let yieldModuleApproveNeededNotificationDescription = Localization.tr("Localizable", "yield_module_approve_needed_notification_description")
  /// Approve needed
  public static let yieldModuleApproveNeededNotificationTitle = Localization.tr("Localizable", "yield_module_approve_needed_notification_title")
  /// The fee will be deducted, and your assets will be resupplied.
  public static let yieldModuleApproveSheetFeeNote = Localization.tr("Localizable", "yield_module_approve_sheet_fee_note")
  /// To continue generating yield, approval is required.
  public static let yieldModuleApproveSheetSubtitle = Localization.tr("Localizable", "yield_module_approve_sheet_subtitle")
  /// Confirm approval
  public static let yieldModuleApproveSheetTitle = Localization.tr("Localizable", "yield_module_approve_sheet_title")
  /// Your funds are currently supplied to the Aave protocol, but you can manage them at any time.
  public static let yieldModuleBalanceInfoSheetSubtitle = Localization.tr("Localizable", "yield_module_balance_info_sheet_subtitle")
  /// Your %@ is supplied to Aave
  public static func yieldModuleBalanceInfoSheetTitle(_ p1: Any) -> String {
    return Localization.tr("Localizable", "yield_module_balance_info_sheet_title", String(describing: p1))
  }
  /// Unable to load chart...
  public static let yieldModuleChartLoadingError = Localization.tr("Localizable", "yield_module_chart_loading_error")
  /// Supplying %1$@ %2$@ to Aave.
  public static func yieldModuleDepositErrorNotificationTitle(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "yield_module_deposit_error_notification_title", String(describing: p1), String(describing: p2))
  }
  /// Disable Yield Mode
  public static let yieldModuleDisableButton = Localization.tr("Localizable", "yield_module_disable_button")
  /// APY %1$@%%
  public static func yieldModuleEarnBadge(_ p1: Any) -> String {
    return Localization.tr("Localizable", "yield_module_earn_badge", String(describing: p1))
  }
  /// Available
  public static let yieldModuleEarnSheetAvailableTitle = Localization.tr("Localizable", "yield_module_earn_sheet_available_title")
  /// Current APY
  public static let yieldModuleEarnSheetCurrentApyTitle = Localization.tr("Localizable", "yield_module_earn_sheet_current_apy_title")
  /// When topping up for lending, a network fee not exceeding %1$@ will be deducted from the balance.
  public static func yieldModuleEarnSheetFeeDescription(_ p1: Any) -> String {
    return Localization.tr("Localizable", "yield_module_earn_sheet_fee_description", String(describing: p1))
  }
  /// The network fee is currently too high to execute lending. Funds will be supplied once it drops to %1$@ or below.
  public static func yieldModuleEarnSheetHighFeeDescription(_ p1: Any) -> String {
    return Localization.tr("Localizable", "yield_module_earn_sheet_high_fee_description", String(describing: p1))
  }
  /// My funds
  public static let yieldModuleEarnSheetMyFundsTitle = Localization.tr("Localizable", "yield_module_earn_sheet_my_funds_title")
  /// Your %1$@ is now deployed to Aave and generating yield. You hold %2$@ tokens, representing your balance and accruing yield automatically. When you top up, the funds are supplied to Aave to generate more yield, after fees are deducted.
  public static func yieldModuleEarnSheetProviderDescription(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "yield_module_earn_sheet_provider_description", String(describing: p1), String(describing: p2))
  }
  /// Yield Mode
  public static let yieldModuleEarnSheetTitle = Localization.tr("Localizable", "yield_module_earn_sheet_title")
  /// Total yield
  public static let yieldModuleEarnSheetTotalEarningsTitle = Localization.tr("Localizable", "yield_module_earn_sheet_total_earnings_title")
  /// Transfers to Aave
  public static let yieldModuleEarnSheetTransfersTitle = Localization.tr("Localizable", "yield_module_earn_sheet_transfers_title")
  /// Explore Aave
  public static let yieldModuleExploreSheetExploreAaveButtonTitle = Localization.tr("Localizable", "yield_module_explore_sheet_explore_aave_button_title")
  /// This is the current supply fee on %@. The actual cost will be shown on the activation tab.
  public static func yieldModuleFeePolicySheetCurrentFeeNote(_ p1: Any) -> String {
    return Localization.tr("Localizable", "yield_module_fee_policy_sheet_current_fee_note", String(describing: p1))
  }
  /// Current fee
  public static let yieldModuleFeePolicySheetCurrentFeeTitle = Localization.tr("Localizable", "yield_module_fee_policy_sheet_current_fee_title")
  /// All future %@ top-ups will be supplied to Aave automatically, after the transaction fee is deducted.
  public static func yieldModuleFeePolicySheetDescription(_ p1: Any) -> String {
    return Localization.tr("Localizable", "yield_module_fee_policy_sheet_description", String(describing: p1))
  }
  /// An approximate network fee of %1$@ (%2$@) will be deducted from each future top-up, and it won't exceed your %3$@ (%4$@) limit.
  public static func yieldModuleFeePolicySheetFeeNote(_ p1: Any, _ p2: Any, _ p3: Any, _ p4: Any) -> String {
    return Localization.tr("Localizable", "yield_module_fee_policy_sheet_fee_note", String(describing: p1), String(describing: p2), String(describing: p3), String(describing: p4))
  }
  /// If network fees rise above the maximum fee, the transaction won't go through until they decrease. You can change this limit later.
  public static let yieldModuleFeePolicySheetMaxFeeNote = Localization.tr("Localizable", "yield_module_fee_policy_sheet_max_fee_note")
  /// Maximum fee
  public static let yieldModuleFeePolicySheetMaxFeeTitle = Localization.tr("Localizable", "yield_module_fee_policy_sheet_max_fee_title")
  /// The minimum amount is calculated based on the current network fee, ensuring it doesn't exceed 4%% of the top-up amount, which equals the minimum %1$@ (%2$@).
  public static func yieldModuleFeePolicySheetMinAmountNote(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "yield_module_fee_policy_sheet_min_amount_note", String(describing: p1), String(describing: p2))
  }
  /// Minimum top-up
  public static let yieldModuleFeePolicySheetMinAmountTitle = Localization.tr("Localizable", "yield_module_fee_policy_sheet_min_amount_title")
  /// Top-up fee policy
  public static let yieldModuleFeePolicySheetTitle = Localization.tr("Localizable", "yield_module_fee_policy_sheet_title")
  /// Tangem also takes a 15%% service fee on yield generated.
  public static let yieldModuleFeePolicyTangemServiceFeeTitle = Localization.tr("Localizable", "yield_module_fee_policy_tangem_service_fee_title")
  /// Your funds will be automatically supplied to Aave once network fees are lower or your balance meets the minimum required amount.
  public static let yieldModuleHighFeeError = Localization.tr("Localizable", "yield_module_high_fee_error")
  /// Fees are higher than usual because the market is very active. You can proceed now or check back later when the fees are lower.
  public static let yieldModuleHighNetworkFeesNotificationDescription = Localization.tr("Localizable", "yield_module_high_network_fees_notification_description")
  /// High Network Fees
  public static let yieldModuleHighNetworkFeesNotificationTitle = Localization.tr("Localizable", "yield_module_high_network_fees_notification_title")
  /// Historical returns
  public static let yieldModuleHistoricalReturns = Localization.tr("Localizable", "yield_module_historical_returns")
  /// Enable %1$@%% APY on your balance
  public static func yieldModuleMainScreenPromoBannerMessage(_ p1: Any) -> String {
    return Localization.tr("Localizable", "yield_module_main_screen_promo_banner_message", String(describing: p1))
  }
  /// Approval for your token in Yield Mode has been revoked. Open the token to grant permission again.
  public static let yieldModuleMainViewApproveNotificationDescription = Localization.tr("Localizable", "yield_module_main_view_approve_notification_description")
  /// Token approval needed
  public static let yieldModuleMainViewApproveNotificationTitle = Localization.tr("Localizable", "yield_module_main_view_approve_notification_title")
  /// Check your network connection
  public static let yieldModuleNetworkFeeUnreachableNotificationDescription = Localization.tr("Localizable", "yield_module_network_fee_unreachable_notification_description")
  /// Network fee info unreachable
  public static let yieldModuleNetworkFeeUnreachableNotificationTitle = Localization.tr("Localizable", "yield_module_network_fee_unreachable_notification_title")
  /// All %1$@ on your account will be supplied to Aave automatically.
  public static func yieldModulePromoScreenAutoBalanceSubtitleV2(_ p1: Any) -> String {
    return Localization.tr("Localizable", "yield_module_promo_screen_auto_balance_subtitle_v2", String(describing: p1))
  }
  /// Auto-supply to Aave
  public static let yieldModulePromoScreenAutoBalanceTitle = Localization.tr("Localizable", "yield_module_promo_screen_auto_balance_title")
  /// Send, swap, or sell your funds instantly, anytime you want.
  public static let yieldModulePromoScreenCashOutSubtitle = Localization.tr("Localizable", "yield_module_promo_screen_cash_out_subtitle")
  /// No lock-ups
  public static let yieldModulePromoScreenCashOutTitle = Localization.tr("Localizable", "yield_module_promo_screen_cash_out_title")
  /// How it works?
  public static let yieldModulePromoScreenHowItWorksButtonTitle = Localization.tr("Localizable", "yield_module_promo_screen_how_it_works_button_title")
  /// Aave is an on-chain protocol that offers non-custodial liquidity markets, enabling users to accrue yield at variable rates.
  public static let yieldModulePromoScreenSelfCustodialSubtitle = Localization.tr("Localizable", "yield_module_promo_screen_self_custodial_subtitle")
  /// Decentralized and self-custodial
  public static let yieldModulePromoScreenSelfCustodialTitle = Localization.tr("Localizable", "yield_module_promo_screen_self_custodial_title")
  /// By using this service, you agree with provider\n%1$@ and %2$@
  public static func yieldModulePromoScreenTermsDisclaimer(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "yield_module_promo_screen_terms_disclaimer", String(describing: p1), String(describing: p2))
  }
  /// Connect to Aave
  public static let yieldModulePromoScreenTitle = Localization.tr("Localizable", "yield_module_promo_screen_title")
  /// Enable %1$@%% APY\non your balance
  public static func yieldModulePromoScreenTitleV2(_ p1: Any) -> String {
    return Localization.tr("Localizable", "yield_module_promo_screen_title_v2", String(describing: p1))
  }
  /// Aave %1$@%% • Variable Interest Rate
  public static func yieldModulePromoScreenVariableRateInfo(_ p1: Any) -> String {
    return Localization.tr("Localizable", "yield_module_promo_screen_variable_rate_info", String(describing: p1))
  }
  /// Variable Interest Rate
  public static let yieldModulePromoScreenVariableRateInfoV2 = Localization.tr("Localizable", "yield_module_promo_screen_variable_rate_info_v2")
  /// Aave
  public static let yieldModuleProvider = Localization.tr("Localizable", "yield_module_provider")
  /// Avg %@
  public static func yieldModuleRateInfoSheetChartAverage(_ p1: Any) -> String {
    return Localization.tr("Localizable", "yield_module_rate_info_sheet_chart_average", String(describing: p1))
  }
  /// Last year's returns
  public static let yieldModuleRateInfoSheetChartTitle = Localization.tr("Localizable", "yield_module_rate_info_sheet_chart_title")
  /// The current interest rate is always variable and automatically computed by Aave's on-chain smart contract, based on real-time supply and demand.
  public static let yieldModuleRateInfoSheetDescription = Localization.tr("Localizable", "yield_module_rate_info_sheet_description")
  /// Powered by
  public static let yieldModuleRateInfoSheetPoweredBy = Localization.tr("Localizable", "yield_module_rate_info_sheet_powered_by")
  /// Interest rate is variable
  public static let yieldModuleRateInfoSheetTitle = Localization.tr("Localizable", "yield_module_rate_info_sheet_title")
  /// When you top up, your funds will be automatically supplied to Aave to start generating yield. %@ will be deducted to cover the transaction fee.
  public static func yieldModuleReceiveSheetDescription(_ p1: Any) -> String {
    return Localization.tr("Localizable", "yield_module_receive_sheet_description", String(describing: p1))
  }
  /// Supply assets
  public static let yieldModuleStartEarning = Localization.tr("Localizable", "yield_module_start_earning")
  /// Your %@ will be supplied to Aave with no lock-ups and will remain fully accessible.
  public static func yieldModuleStartEarningSheetDescription(_ p1: Any) -> String {
    return Localization.tr("Localizable", "yield_module_start_earning_sheet_description", String(describing: p1))
  }
  /// See top-up fee policy
  public static let yieldModuleStartEarningSheetFeePolicy = Localization.tr("Localizable", "yield_module_start_earning_sheet_fee_policy")
  /// Your next top-ups will be automatically supplied to Aave.
  public static let yieldModuleStartEarningSheetNextDeposits = Localization.tr("Localizable", "yield_module_start_earning_sheet_next_deposits")
  /// All your future incoming %1$@ deposits will be automatically supplied to Aave.
  public static func yieldModuleStartEarningSheetNextDepositsV2(_ p1: Any) -> String {
    return Localization.tr("Localizable", "yield_module_start_earning_sheet_next_deposits_v2", String(describing: p1))
  }
  /// Active
  public static let yieldModuleStatusActive = Localization.tr("Localizable", "yield_module_status_active")
  /// Paused
  public static let yieldModuleStatusPaused = Localization.tr("Localizable", "yield_module_status_paused")
  /// Disabling Yield Mode
  public static let yieldModuleStopEarning = Localization.tr("Localizable", "yield_module_stop_earning")
  /// Turning this off will withdraw your assets from Aave, convert them back to %@ in your wallet, and stop yield accrual.
  public static func yieldModuleStopEarningSheetDescription(_ p1: Any) -> String {
    return Localization.tr("Localizable", "yield_module_stop_earning_sheet_description", String(describing: p1))
  }
  /// A network fee is charged by the blockchain when you exit Yield Mode.
  public static let yieldModuleStopEarningSheetFeeNote = Localization.tr("Localizable", "yield_module_stop_earning_sheet_fee_note")
  /// Disable Yield Mode
  public static let yieldModuleStopEarningSheetTitle = Localization.tr("Localizable", "yield_module_stop_earning_sheet_title")
  /// Supply
  public static let yieldModuleSupply = Localization.tr("Localizable", "yield_module_supply")
  /// Supply APY
  public static let yieldModuleSupplyApr = Localization.tr("Localizable", "yield_module_supply_apr")
  /// APY
  public static let yieldModuleTokenDetailsEarnNotificationApy = Localization.tr("Localizable", "yield_module_token_details_earn_notification_apy")
  /// Interest accrues automatically
  public static let yieldModuleTokenDetailsEarnNotificationDescription = Localization.tr("Localizable", "yield_module_token_details_earn_notification_description")
  /// Interest accrues automatically
  public static let yieldModuleTokenDetailsEarnNotificationEarningOnYourBalanceSubtitle = Localization.tr("Localizable", "yield_module_token_details_earn_notification_earning_on_your_balance_subtitle")
  /// Yield Mode
  public static let yieldModuleTokenDetailsEarnNotificationEarningOnYourBalanceTitle = Localization.tr("Localizable", "yield_module_token_details_earn_notification_earning_on_your_balance_title")
  /// Enabling Yield Mode
  public static let yieldModuleTokenDetailsEarnNotificationProcessing = Localization.tr("Localizable", "yield_module_token_details_earn_notification_processing")
  /// Yield Mode
  public static let yieldModuleTokenDetailsEarnNotificationTitle = Localization.tr("Localizable", "yield_module_token_details_earn_notification_title")
  /// Yield Mode contract deploy
  public static let yieldModuleTransactionDeployContract = Localization.tr("Localizable", "yield_module_transaction_deploy_contract")
  /// Yield Mode enabled
  public static let yieldModuleTransactionEnter = Localization.tr("Localizable", "yield_module_transaction_enter")
  /// %1$@ supplied to Aave
  public static func yieldModuleTransactionEnterSubtitle(_ p1: Any) -> String {
    return Localization.tr("Localizable", "yield_module_transaction_enter_subtitle", String(describing: p1))
  }
  /// Yield Mode disabled
  public static let yieldModuleTransactionExit = Localization.tr("Localizable", "yield_module_transaction_exit")
  /// %1$@ withdrawn from Aave
  public static func yieldModuleTransactionExitSubtitle(_ p1: Any) -> String {
    return Localization.tr("Localizable", "yield_module_transaction_exit_subtitle", String(describing: p1))
  }
  /// Yield Mode initialized
  public static let yieldModuleTransactionInitialize = Localization.tr("Localizable", "yield_module_transaction_initialize")
  /// Yield Mode reactivated
  public static let yieldModuleTransactionReactivate = Localization.tr("Localizable", "yield_module_transaction_reactivate")
  /// Supply to Aave
  public static let yieldModuleTransactionTopup = Localization.tr("Localizable", "yield_module_transaction_topup")
  /// %1$@ supplied to Aave
  public static func yieldModuleTransactionTopupSubtitle(_ p1: Any) -> String {
    return Localization.tr("Localizable", "yield_module_transaction_topup_subtitle", String(describing: p1))
  }
  /// Withdraw from Aave
  public static let yieldModuleTransactionWithdraw = Localization.tr("Localizable", "yield_module_transaction_withdraw")
  /// Automatic
  public static let yieldModuleTransferModeAutomatic = Localization.tr("Localizable", "yield_module_transfer_mode_automatic")
  /// Add some %1$@ %2$@ to cover the network fee for transactions.
  public static func yieldModuleUnableToCoverFeeDescription(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "yield_module_unable_to_cover_fee_description", String(describing: p1), String(describing: p2))
  }
  /// Unable to cover %@ fee
  public static func yieldModuleUnableToCoverFeeTitle(_ p1: Any) -> String {
    return Localization.tr("Localizable", "yield_module_unable_to_cover_fee_title", String(describing: p1))
  }
  /// Yield Mode isn't available at the moment. Please try again later.
  public static let yieldModuleUnavailableSubtitle = Localization.tr("Localizable", "yield_module_unavailable_subtitle")
  /// Yield Mode unavailable
  public static let yieldModuleUnavailableTitle = Localization.tr("Localizable", "yield_module_unavailable_title")
  /// Unable to load chart...
  public static let yieldSupplyChartLoadingError = Localization.tr("Localizable", "yield_supply_chart_loading_error")
}

// MARK: - Implementation Details

private extension Localization {
  static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

private class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
      return Bundle.module
    #else
      return Bundle(for: BundleToken.self)
    #endif
  }()
}
