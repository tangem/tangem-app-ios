//
//  AppSettings.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

class AppSettings {
    @AppStorageCompat(StorageType.twinCardOnboardingDisplayed)
    var isTwinCardOnboardingWasDisplayed: Bool = false

    @AppStorageCompat(StorageType.numberOfAppLaunches)
    var numberOfLaunches: Int = 0

    @AppStorageCompat(StorageType.didUserRespondToRateApp)
    var didUserRespondToRateApp: Bool = false

    @AppStorageCompat(StorageType.dismissRateAppAtLaunch)
    var dismissRateAppAtLaunch: Int? = nil

    @AppStorageCompat(StorageType.positiveBalanceAppearanceDate)
    var positiveBalanceAppearanceDate: Date? = nil

    @AppStorageCompat(StorageType.positiveBalanceAppearanceLaunch)
    var positiveBalanceAppearanceLaunch: Int? = nil

    @AppStorageCompat(StorageType.searchedCards)
    var searchedCards: [String] = []

    @AppStorageCompat(StorageType.scannedNdefs)
    var scannedNdefs: [String] = []

    @AppStorageCompat(StorageType.lastScannedNdef)
    var lastScannedNdef: String = ""

    @AppStorageCompat(StorageType.cardsStartedActivation)
    var cardsStartedActivation: [String] = []

    @AppStorageCompat(StorageType.didDisplayMainScreenStories)
    var didDisplayMainScreenStories: Bool = false

    // Temp migrated cards storage. Remove with LegacyCardMigrator
    @AppStorageCompat(StorageType.migratedCardsWithDefaultTokens)
    var migratedCardsWithDefaultTokens: [String] = []

    @AppStorageCompat(StorageType.validatedSignedHashesCards)
    var validatedSignedHashesCards: [String] = []

    @AppStorageCompat(StorageType.selectedCurrencyCode)
    var selectedCurrencyCode: String = "USD"

    @AppStorageCompat(StorageType.termsOfServiceAccepted)
    var termsOfServicesAccepted: [String] = []

    @AppStorageCompat(StorageType.askedToSaveUserWallets)
    var askedToSaveUserWallets: Bool = false

    @AppStorageCompat(StorageType.saveUserWallets)
    var saveUserWallets: Bool = false

    @AppStorageCompat(StorageType.selectedUserWalletId)
    var selectedUserWalletId: Data = Data()

    @AppStorageCompat(StorageType.saveAccessCodes)
    var saveAccessCodes: Bool = false

    static let shared: AppSettings = { .init() }()

    private init() {}

    deinit {
        AppLog.shared.debug("AppSettings deinit")
    }
}
