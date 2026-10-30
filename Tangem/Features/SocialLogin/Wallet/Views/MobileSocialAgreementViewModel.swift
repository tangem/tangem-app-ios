//
//  MobileSocialAgreementViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemAssets
import TangemFoundation
import TangemLocalization

final class MobileSocialAgreementViewModel: ObservableObject {
    @Injected(\.safariManager) private var safariManager: SafariManager

    @Published var isEmailSharingAccepted = false
    @Published var isLossRiskAccepted = false

    @Published private(set) var hasLossRiskWarning = false

    let infoTitle = Localization.socialLoginConsentTitle(MobileBackupConstants.appleServiceName)
    let learnMoreTitle = Localization.socialLoginConsentLearnMore
    let emailSharingTitle = Localization.socialLoginConsentEmailSharing
    let lossRiskTitle = Localization.socialLoginConsentAcknowledge(MobileBackupConstants.appleServiceName)
    let actionTitle = Localization.socialAgreementActionCreate

    var infoDescription: AttributedString {
        makeInfoDescription()
    }

    let learnMoreURL = MobileSocialLoginUrlBuilder().learnMoreURL()

    private let analyticsLogger = MobileSocialLoginAnalyticsLogger()

    private weak var coordinator: MobileSocialAgreementRoutable?

    init(coordinator: MobileSocialAgreementRoutable) {
        self.coordinator = coordinator
        bind()
    }
}

// MARK: - Internal methods

extension MobileSocialAgreementViewModel {
    func onFirstAppear() {
        analyticsLogger.logRiskConsentScreenOpened()
    }

    func onActionTap() {
        updateLossRiskWarning()
        acceptIfNeeded()
    }

    func onLearnMoreTap(url: URL) {
        safariManager.openURL(url)
    }

    func onCloseTap() {
        runTask(in: self) { viewModel in
            await viewModel.close()
        }
    }
}

// MARK: - Private methods

private extension MobileSocialAgreementViewModel {
    func bind() {
        $isLossRiskAccepted
            .dropFirst()
            .map { !$0 }
            .assign(to: &$hasLossRiskWarning)
    }

    func acceptIfNeeded() {
        guard isLossRiskAccepted else {
            FeedbackGenerator.error()
            analyticsLogger.logRiskConsentNotConfirmedError()
            return
        }

        let marketingConsent = MobileSocialMarketingConsent(
            isGiven: isEmailSharingAccepted,
            consentText: emailSharingTitle
        )

        runTask(in: self) { viewModel in
            await viewModel.accept(marketingConsent: marketingConsent)
        }
    }

    func updateLossRiskWarning() {
        hasLossRiskWarning = !isLossRiskAccepted
    }
}

// MARK: - Helpers

private extension MobileSocialAgreementViewModel {
    func makeInfoDescription() -> AttributedString {
        let description = Localization.socialLoginConsentDescription(MobileBackupConstants.appleServiceName)
        var text = AttributedString("\(description) \(learnMoreTitle)")

        if let range = text.range(of: learnMoreTitle) {
            text[range].link = learnMoreURL
            text[range].foregroundColor = DesignSystem.Color.textPrimary
        }

        return text
    }
}

// MARK: - Routing

@MainActor
private extension MobileSocialAgreementViewModel {
    func accept(marketingConsent: MobileSocialMarketingConsent) {
        coordinator?.onSocialAgreementAccept(marketingConsent: marketingConsent)
    }

    func close() {
        coordinator?.onSocialAgreementClose()
    }
}
