//
//  AppSettings.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemPay

final class AppSettings {
    @AppStorageCompat(StorageType.twinCardOnboardingDisplayed)
    var isTwinCardOnboardingWasDisplayed: Bool = false

    @AppStorageCompat(StorageType.numberOfAppLaunches)
    var numberOfLaunches: Int = 0

    @AppStorageCompat(StorageType.startAppUsageDate)
    var startAppUsageDate: Date? = nil

    @AppStorageCompat(StorageType.cardsStartedActivation)
    var cardsStartedActivation: [String] = []

    @AppStorageCompat(StorageType.validatedSignedHashesCards)
    var validatedSignedHashesCards: [String] = []

    @AppStorageCompat(StorageType.selectedCurrencyCode)
    var selectedCurrencyCode: String = "USD"

    @AppStorageCompat(StorageType.termsOfServiceAccepted)
    var termsOfServicesAccepted: [String] = []

    @AppStorageCompat(StorageType.useBiometricAuthentication)
    var useBiometricAuthentication: Bool = false

    @AppStorageCompat(StorageType.askedToSaveUserWallets)
    var askedToSaveUserWallets: Bool = false

    @AppStorageCompat(StorageType.saveUserWallets)
    var saveUserWallets: Bool = false

    @AppStorageCompat(StorageType.selectedUserWalletId)
    var selectedUserWalletId: Data = .init()

    @AppStorageCompat(StorageType.saveAccessCodes)
    var saveAccessCodes: Bool = false

    var requireAccessCodes: Bool {
        get { !saveAccessCodes }
        set { saveAccessCodes = !newValue }
    }

    @AppStorageCompat(StorageType.systemDeprecationWarningDismissDate)
    var systemDeprecationWarningDismissalDate: Date? = nil

    @AppStorageCompat(StorageType.understandsAddressNetworkRequirements)
    var understandsAddressNetworkRequirements: [String] = []

    @AppStorageCompat(StorageType.promotionQuestionnaireFinished)
    var promotionQuestionnaireFinished: Bool = false

    @AppStorageCompat(StorageType.hideSensitiveInformation)
    var isHidingSensitiveInformation: Bool = false

    @AppStorageCompat(StorageType.hideSensitiveAvailable)
    var isHidingSensitiveAvailable: Bool = false

    @AppStorageCompat(StorageType.shouldHidingSensitiveInformationSheetShowing)
    var shouldHidingSensitiveInformationSheetShowing: Bool = true

    @AppStorageCompat(StorageType.appTheme, store: .standard)
    var appTheme: ThemeOption = .system

    @AppStorageCompat(StorageType.userDidSwipeWalletsOnMainScreen)
    var userDidSwipeWalletsOnMainScreen: Bool = false

    @AppStorageCompat(StorageType.mainPromotionDismissed)
    var mainPromotionDismissed: [String] = []

    @AppStorageCompat(StorageType.tokenPromotionDismissed)
    var tokenPromotionDismissed: [String] = []

    @AppStorageCompat(StorageType.userDidTapSendScreenSummary)
    var userDidTapSendScreenSummary: Bool = false

    @AppStorageCompat(StorageType.forcedDemoCardId)
    var forcedDemoCardId: String? = nil

    @AppStorageCompat(StorageType.userWalletIdsWithRing)
    var userWalletIdsWithRing: [String] = []

    @AppStorageCompat(StorageType.shownStoryIds)
    var shownStoryIds: [String] = []

    @AppStorageCompat(StorageType.supportSeedNotificationShownDate)
    var supportSeedNotificationShownDate: Date? = nil

    @AppStorageCompat(StorageType.userWalletIdsWithNFTEnabled)
    var userWalletIdsWithNFTEnabled: [String] = []

    @AppStorageCompat(StorageType.marketsTooltipWasShown)
    var marketsTooltipWasShown: Bool = false

    @AppStorageCompat(StorageType.tronWarningWithdrawTokenDisplayed)
    var tronWarningWithdrawTokenDisplayed: Int = 0

    @AppStorageCompat(StorageType.applicationUid)
    var applicationUid: String = ""

    @AppStorageCompat(StorageType.lastStoredFCMToken)
    var lastStoredFCMToken: String? = nil

    @AppStorageCompat(StorageType.didMigrateWalletConnectSavedSessions)
    var didMigrateWalletConnectSavedSessions: Bool = false

    @AppStorageCompat(StorageType.didMigrateWalletConnectToV2)
    var didMigrateWalletConnectToAccounts: Bool = false

    @AppStorageCompat(StorageType.allowanceUserWalletIdTransactionsPush)
    var allowanceUserWalletIdTransactionsPush: [String] = []

    @AppStorageCompat(StorageType.isSendWithSwapOnboardNotificationHidden)
    var isSendWithSwapOnboardNotificationHidden: Bool = false

    @AppStorageCompat(StorageType.settingsVersion)
    var settingsVersion: Int = 0

    @AppStorageCompat(StorageType.tangemPayCardIssuingOrderIdForCustomerWalletId)
    var tangemPayCardIssuingOrderIdForCustomerWalletId: [String: String] = [:]

    @AppStorageCompat(StorageType.tangemPayShowAddToApplePayGuide)
    var tangemPayShowAddToApplePayGuide: Bool = true

    @AppStorageCompat(StorageType.tangemPayIsPaeraCustomer)
    var tangemPayIsPaeraCustomer: [String: Bool] = [:]

    @AppStorageCompat(StorageType.tangemPayIsKYCHiddenForCustomerWalletId)
    var tangemPayIsKYCHiddenForCustomerWalletId: [String: Bool] = [:]

    @AppStorageCompat(StorageType.tangemPayIsEligibilityAvailable)
    var tangemPayIsEligibilityAvailable: Bool = false

    @AppStorageCompat(StorageType.tangemPayShouldShowGetBanner)
    var tangemPayShouldShowGetBanner: Bool = true

    @AppStorageCompat(StorageType.jailbreakWarningWasShown)
    var jailbreakWarningWasShown: Bool = false

    @AppStorageCompat(StorageType.showMarketsYieldModeNotification)
    var showMarketsYieldModeNotification = true

    static let shared: AppSettings = .init()

    private init() {}

    deinit {
        AppLogger.debug(self)
    }
}

extension AppSettings: TangemPayOrderIdStorage {
    func cardIssuingOrderId(customerWalletId: String) -> String? {
        tangemPayCardIssuingOrderIdForCustomerWalletId[customerWalletId]
    }

    func saveCardIssuingOrderId(_ orderId: String, customerWalletId: String) {
        tangemPayCardIssuingOrderIdForCustomerWalletId[customerWalletId] = orderId
    }

    func deleteCardIssuingOrderId(customerWalletId: String) {
        tangemPayCardIssuingOrderIdForCustomerWalletId[customerWalletId] = nil
    }
}

extension AppSettings: TangemPayPaeraCustomerFlagRepository {
    func isPaeraCustomer(customerWalletId: String) -> Bool {
        tangemPayIsPaeraCustomer[customerWalletId, default: false]
    }

    func isKYCHidden(customerWalletId: String) -> Bool {
        tangemPayIsKYCHiddenForCustomerWalletId[customerWalletId, default: false]
    }

    func setIsPaeraCustomer(_ value: Bool, for customerWalletId: String) {
        tangemPayIsPaeraCustomer[customerWalletId] = value
    }

    func setIsKYCHidden(_ value: Bool, for customerWalletId: String) {
        tangemPayIsKYCHiddenForCustomerWalletId[customerWalletId] = value
    }

    func setShouldShowGetBanner(_ value: Bool) {
        tangemPayShouldShowGetBanner = value
    }
}
