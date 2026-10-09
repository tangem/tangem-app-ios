//
//  WelcomeAnalyticsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// One button — one event: every tappable element gets its own event instead of a shared
/// event with a path property, so funnels build without filters.
protocol WelcomeAnalyticsProvider {
    func logIntroductionProcessScreenOpened(entryReason: Analytics.ParameterValue)
    func logWelcomeMediaError(stage: Analytics.ParameterValue)
    func logLegalOpened(document: Analytics.ParameterValue)

    func logCreateWalletButton()
    func logIHaveWalletButton()
    func logCreateWalletIntroScreenOpened()
    func logIHaveWalletIntroScreenOpened()
    func logSheetDismissed(sheet: Analytics.ParameterValue, reason: Analytics.ParameterValue)

    func logHardwareWalletButton()
    func logMobileWalletButton()
    func logSignInWithCardButton()
    func logImportExistingWalletButton()
    func logImportWalletRequest(hasCloudBackup: Bool)

    func logButtonScanCard()
    func logCardWasScanned(contextParams: Analytics.ContextParams)
    func logScanCancelled()
    func logScanError(_ error: Error)
    func logScanTroubleshooting()
    func logTroubleshootingTryAgain()
    func logTroubleshootingReadMore()
    func logTroubleshootingRequestSupport()
    func logCardSignIn(userWalletModel: UserWalletModel)

    func logButtonBuy()
    func logButtonBuyTangem()
    func logShopScreenOpened()
}

// MARK: - Dependencies

private struct WelcomeAnalyticsProviderKey: InjectionKey {
    static var currentValue: WelcomeAnalyticsProvider = CommonWelcomeAnalyticsService()
}

extension InjectedValues {
    var welcomeAnalyticsProvider: WelcomeAnalyticsProvider {
        get { Self[WelcomeAnalyticsProviderKey.self] }
        set { Self[WelcomeAnalyticsProviderKey.self] = newValue }
    }
}
