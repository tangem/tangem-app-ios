//
//  StorageType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

enum StorageType: String {
	case scannedCards = "tangem_tap_scanned_cards"
	case oldDeviceOldCardAlert = "tangem_tap_oldDeviceOldCard_shown"
	case selectedCurrencyCode = "tangem_tap_selected_currency_code"
	case termsOfServiceAccepted = "tangem_tap_terms_of_service_accepted"
	case firstTimeScan = "tangem_tap_first_time_scan"
	case validatedSignedHashesCards = "tangem_tap_validated_signed_hashes_cards"
	case twinCardOnboardingDisplayed = "tangem_tap_twin_card_onboarding_displayed"
	case numberOfAppLaunches = "tangem_tap_number_of_launches"
    case readWarningHashes = "tangem_tap_read_warnings"
    case didUserRespondToRateApp = "tangem_tap_rate_app_responded"
    case dismissRateAppAtLaunch = "tangem_tap_dismiss_rate_app_at_launch_number"
    case positiveBalanceAppearanceDate = "tangem_tap_positive_balace_appearance_date"
    case positiveBalanceAppearanceLaunch = "tangem_tap_positive_balance_appearance_launch"
    case searchedCards = "tangem_tap_searched_cards" //for tokens search
    case scannedNdefs = "tangem_tap_scanned_ndefs"
    case lastScannedNdef = "tangem_tap_last_scanned_ndef"
    case isMigratedToNewUserDefaults = "tangem_tap_migrate_to_new_defaults"
    case cardsStartedActivation = "tangem_cards_started_activation"
    case cardsFinishedActivation = "tangem_cards_finished_activation"
    case didDisplayMainScreenStories = "tangem_tap_did_display_main_screen_stories"
    case fundsRestorationAlert = "tangem_funds_restoration_alert"
    
    //Temp migrated cards storage. Remove with LegacyCardMigrator
    case migratedCardsWithDefaultTokens = "tangem_migrated_cards_default_tokens"
}
