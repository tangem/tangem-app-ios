//
//  AddWalletAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct AddWalletAnalyticsLogger {
    private let socialLoginAnalyticsLogger = MobileSocialLoginAnalyticsLogger()
    private let creationAnalyticsLogger = MobileWalletCreationAnalyticsLogger()

    func logHardwareWalletTap() {
        Analytics.log(.settingsButtonAddHardwareWallet, params: [.wallets: walletsParameterValue])
    }

    func logAppleSignInTap() {
        socialLoginAnalyticsLogger.logContinueWithAppleButton(source: .addNewWallet)
    }

    func logAppleSignInMinOSNotSupportedNotice() {
        socialLoginAnalyticsLogger.logMinOSNotSupportedNotice()
    }

    func logSeedPhraseWalletTap() {
        Analytics.log(
            .buttonMobileWallet,
            params: [.source: .addNewWallet],
            contextParams: .empty
        )
    }

    func logImportWalletTap() {
        Analytics.log(
            event: .introductionProcessButtonImportExistingWallet,
            params: [
                .productType: Analytics.ProductType.mobileWallet.rawValue,
                .source: Analytics.ParameterValue.addNewWallet.rawValue,
            ],
            contextParams: .empty
        )
    }

    func logMobileWalletLimitNotice(restriction: MobileWalletLimitUtil.Restriction) {
        Analytics.log(
            event: .settingsNoticeMobileWalletLimit,
            params: restriction.analyticsParams,
            contextParams: .empty
        )
    }

    func logSheetDismissed(sheet: Analytics.ParameterValue, reason: Analytics.ParameterValue) {
        Analytics.log(
            .introductionProcessSheetDismissed,
            params: [.sheet: sheet, .dismissReason: reason],
            contextParams: .empty
        )
    }

    func logWalletCreated() {
        creationAnalyticsLogger.logWalletCreated(source: .addNewWallet)
    }
}

// MARK: - Private

private extension AddWalletAnalyticsLogger {
    var walletsParameterValue: Analytics.ParameterValue {
        switch UserWalletRepositoryModeHelper.mode {
        case .mobile: .walletsTypeMobile
        case .hardware: .walletsTypeCold
        case .mixed: .walletsTypeMultiple
        case .empty: .unknown
        }
    }
}
