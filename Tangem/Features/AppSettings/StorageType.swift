//
//  StorageType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

enum StorageType: String {
    case selectedCurrencyCode = "tangem_tap_selected_currency_code"
    case termsOfServiceAccepted = "tangem_tap_terms_of_service_accepted"
    case validatedSignedHashesCards = "tangem_tap_validated_signed_hashes_cards"
    case twinCardOnboardingDisplayed = "tangem_tap_twin_card_onboarding_displayed"
    case numberOfAppLaunches = "tangem_tap_number_of_launches"
    case cardsStartedActivation = "tangem_cards_started_activation"
    case askedToSaveUserWallets = "tangem_asked_to_save_user_wallets"
    case saveUserWallets = "tangem_save_user_wallets"
    case selectedUserWalletId = "tangem_selected_user_wallet_id"
    case saveAccessCodes = "tangem_save_access_codes"
    case systemDeprecationWarningDismissDate = "tangem_system_deprecation_warning_dismiss_date"
    case understandsAddressNetworkRequirements = "tangem_understands_address_network_requirements"
    case promotionQuestionnaireFinished = "promotion_questionnaire_finished"
    case hideSensitiveInformation = "hide_sensitive_information"
    case hideSensitiveAvailable = "hide_sensitive_available"
    case shouldHidingSensitiveInformationSheetShowing = "should_hiding_sensitive_information_sheet_showing"
    case appTheme = "app_theme"
    case userDidSwipeWalletsOnMainScreen = "user_did_swipe_wallets_on_main_screen"
    case mainPromotionDismissed = "main_promotion_dismissed"
    case tokenPromotionDismissed = "token_promotion_dismissed"
    case userDidTapSendScreenSummary = "user_did_tap_send_screen_summary"
    case pendingBackups = "pending_backups"
    case pendingBackupsCurrentID = "pending_backups_current_id"
    case forcedDemoCardId = "forced_demo_card_id"
    case userWalletIdsWithRing = "tangem_userwalletIds_with_ring"
    case shownStoryIds = "shown_story_ids"
    case supportSeedNotificationShownDate = "support_seed_notification_shown_date"
    case userWalletIdsWithNFTEnabled = "user_wallet_ids_with_nft_enabled"
    case marketsTooltipWasShown = "tangem_markets_tooltip_was_shown"
    case startWalletUsageDate = "tangem_start_wallet_usage_date"
    case startAppUsageDate = "tangem_start_app_usage_date"
    case tronWarningWithdrawTokenDisplayed = "tron_warning_withdraw_token_displayed"
    case applicationUid = "application_uid"
    case lastStoredFCMToken = "last_stored_FCM_token"
    case didMigrateWalletConnectSavedSessions = "tangem_did_migrate_wallet_connect_saved_sessions"
    case didMigrateWalletConnectToV2 = "tangem_did_migrate_wallet_connect_to_v2"
    case allowanceUserWalletIdTransactionsPush = "allowance_user_wallet_id_transactions_push"
    case isSendWithSwapOnboardNotificationHidden = "is_send_with_swap_onboard_notification_hidden"
    case useBiometricAuthentication = "use_biometric_authentication"
    case settingsVersion = "settings_version"
    case tangemPayCardIssuingOrderIdForCustomerWalletId = "tangem_pay_card_issuing_order_id_for_customer_wallet_id"
    case tangemPayShowAddToApplePayGuide = "tangem_pay_show_add_to_apple_pay_guide"
    case tangemPayIsPaeraCustomer = "tangem_pay_is_paera_customer"
    case tangemPayShouldShowGetBanner = "tangem_pay_should_show_get_banner"
    case jailbreakWarningWasShown = "jailbreak_warning_was_shown"
}
