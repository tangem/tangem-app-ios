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

    @AppStorageCompat(StorageType.userDidTapSendScreenSummary)
    var userDidTapSendScreenSummary: Bool = false

    @AppStorageCompat(StorageType.forcedDemoCardId)
    var forcedDemoCardId: String? = nil

    @AppStorageCompat(StorageType.userWalletIdsWithRing)
    var userWalletIdsWithRing: [String] = []

    @AppStorageCompat(StorageType.shownStoryIds)
    var shownStoryIds: [String] = []

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

    @AppStorageCompat(StorageType.tangemPayShowAddToApplePayGuide)
    var tangemPayShowAddToApplePayGuide: Bool = true

    @AppStorageCompat(StorageType.tangemPayIsPaeraCustomer)
    var tangemPayIsPaeraCustomer: [String: Bool] = [:]

    @AppStorageCompat(StorageType.tangemPayIsDisabledForCustomerWalletId)
    var tangemPayIsDisabledForCustomerWalletId: [String: Bool] = [:]

    @AppStorageCompat(StorageType.tangemPayIsKYCHiddenForCustomerWalletId)
    var tangemPayIsKYCHiddenForCustomerWalletId: [String: Bool] = [:]

    @AppStorageCompat(StorageType.tangemPayEligibleDistributionChannels)
    var tangemPayEligibleDistributionChannels: [String] = []

    @AppStorageCompat(StorageType.tangemPayShouldShowGetBanner)
    var tangemPayShouldShowGetBanner: Bool = true

    @AppStorageCompat(StorageType.tangemPayCachedLocalState)
    var tangemPayCachedLocalState: [String: String] = [:]

    @AppStorageCompat(StorageType.tangemPayCachedTransactionHistory)
    var tangemPayCachedTransactionHistory: [String: String] = [:]

    @AppStorageCompat(StorageType.tangemPayCachedCustomerInfo)
    var tangemPayCachedCustomerInfo: [String: String] = [:]

    @AppStorageCompat(StorageType.jailbreakWarningWasShown)
    var jailbreakWarningWasShown: Bool = false

    @AppStorageCompat(StorageType.referralRefcode)
    var referralRefcode: String? = nil

    @AppStorageCompat(StorageType.referralCampaign)
    var referralCampaign: String? = nil

    @AppStorageCompat(StorageType.hasReferralBindingRequest)
    var hasReferralBindingRequest: Bool = false

    @AppStorageCompat(StorageType.shouldShowMobilePromoWalletSelector)
    var shouldShowMobilePromoWalletSelector: Bool = false

    static let shared: AppSettings = .init()

    private init() {}

    deinit {
        AppLogger.debug("AppSettings deinit")
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

    func isTangemPayDisabled(customerWalletId: String) -> Bool {
        tangemPayIsDisabledForCustomerWalletId[customerWalletId, default: false]
    }

    func setIsTangemPayDisabled(_ value: Bool, for customerWalletId: String) {
        tangemPayIsDisabledForCustomerWalletId[customerWalletId] = value
    }

    func setShouldShowGetBanner(_ value: Bool) {
        tangemPayShouldShowGetBanner = value
    }
}

extension AppSettings: TangemPayCachedStateStorage {
    func cachedLocalState(customerWalletId: String) -> TangemPayCachedLocalState? {
        guard let jsonString = tangemPayCachedLocalState[customerWalletId],
              let data = jsonString.data(using: .utf8)
        else {
            return nil
        }

        return try? JSONDecoder().decode(TangemPayCachedLocalState.self, from: data)
    }

    func saveCachedLocalState(_ state: TangemPayCachedLocalState, customerWalletId: String) {
        guard let data = try? JSONEncoder().encode(state),
              let jsonString = String(data: data, encoding: .utf8)
        else {
            return
        }

        tangemPayCachedLocalState[customerWalletId] = jsonString
    }
}

extension AppSettings: TangemPayCustomerInfoCacheStorage {
    func cachedCustomerInfo(customerWalletId: String) -> VisaCustomerInfoResponse? {
        guard let jsonString = tangemPayCachedCustomerInfo[customerWalletId],
              let data = jsonString.data(using: .utf8)
        else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(VisaCustomerInfoResponse.self, from: data)
    }

    func saveCachedCustomerInfo(_ customerInfo: VisaCustomerInfoResponse, customerWalletId: String) {
        let sanitized = customerInfo.sanitizedForDiskCache()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(sanitized),
              let jsonString = String(data: data, encoding: .utf8)
        else {
            return
        }

        tangemPayCachedCustomerInfo[customerWalletId] = jsonString
    }

    func clearCachedCustomerInfo(customerWalletId: String) {
        tangemPayCachedCustomerInfo[customerWalletId] = nil
    }
}

extension AppSettings: TangemPayTransactionHistoryCacheStorage {
    private enum TangemPayTransactionHistoryCacheConstants {
        /// Limits per-customer transaction cache to last N records to keep UserDefaults small.
        static let maxRecords = 50
    }

    func cachedTransactions(customerWalletId: String) -> [TangemPayTransactionRecord]? {
        guard let jsonString = tangemPayCachedTransactionHistory[customerWalletId],
              let data = jsonString.data(using: .utf8)
        else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode([TangemPayTransactionRecord].self, from: data)
    }

    func saveCachedTransactions(_ transactions: [TangemPayTransactionRecord], customerWalletId: String) {
        let trimmed = Array(transactions.prefix(TangemPayTransactionHistoryCacheConstants.maxRecords))

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(trimmed),
              let jsonString = String(data: data, encoding: .utf8)
        else {
            return
        }

        tangemPayCachedTransactionHistory[customerWalletId] = jsonString
    }
}
