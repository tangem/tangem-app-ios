//
//  MobileSocialLoginAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct MobileSocialLoginAnalyticsLogger {
    private let creationAnalyticsLogger = MobileWalletCreationAnalyticsLogger()

    func logContinueWithAppleButton(source: MobileSocialLoginSource) {
        Analytics.log(
            .socialLoginButtonContinueWithApple,
            params: [.source: source.analyticsParameterValue],
            contextParams: contextParams
        )
    }

    func logMinOSNotSupportedNotice() {
        Analytics.log(.socialLoginNoticeMinOSNotSupported, contextParams: contextParams)
    }

    func logRiskConsentScreenOpened() {
        Analytics.log(.socialLoginRiskConsentScreenOpened, contextParams: contextParams)
    }

    func logRiskConsentNotConfirmedError() {
        Analytics.log(.socialLoginErrorRiskConsentNotConfirmed, contextParams: contextParams)
    }

    func logMarketingEmailsConsent(_ consent: MobileSocialMarketingConsent) {
        Analytics.log(
            event: .socialLoginConsentMarketingEmails,
            params: [
                .consentType: Analytics.ParameterValue.consentTypeMarketingEmails.rawValue,
                .consentGiven: Analytics.ParameterValue.affirmativeOrNegative(for: consent.isGiven).rawValue,
                .consentText: consent.consentText,
            ],
            contextParams: contextParams
        )
    }

    func logErrorShown(message: String) {
        Analytics.log(
            event: .socialLoginErrorShown,
            params: [.errorMessage: message],
            contextParams: contextParams
        )
    }

    func logWalletCreated() {
        creationAnalyticsLogger.logWalletCreated(source: .socialLogin)
    }

    func logWalletRestored() {
        creationAnalyticsLogger.logWalletRestored(source: .socialLogin)
    }
}

// MARK: - Private methods

private extension MobileSocialLoginAnalyticsLogger {
    var contextParams: Analytics.ContextParams {
        .custom(.mobileWallet)
    }
}
