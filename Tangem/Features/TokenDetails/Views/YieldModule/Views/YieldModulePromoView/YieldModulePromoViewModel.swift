//
//  YieldModulePromoViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets

final class YieldModulePromoViewModel {
    // MARK: - Injected

    @Injected(\.safariManager)
    private var safariManager: SafariManager

    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    // MARK: - Dependencies

    private let walletModel: any WalletModel
    private weak var coordinator: YieldModulePromoCoordinator?
    private weak var tokenDetailsCoordinator: TokenDetailsRoutable?

    // MARK: - Properties

    private(set) var apy: String
    private(set) var tosUrl = URL(string: "https://tangem.com")!
    private(set) var privacyPolicyUrl = URL(string: "https://tangem.com")!
    private(set) var howIrWorksUrl = URL(string: "https://tangem.com")!

    private let startEarnAction: () -> Void

    // MARK: - Init

    init(
        walletModel: any WalletModel,
        apy: String,
        coordinator: YieldModulePromoCoordinator,
        startEarnAction: @escaping () -> Void
    ) {
        self.walletModel = walletModel
        self.coordinator = coordinator
        self.apy = apy
        self.startEarnAction = startEarnAction
    }

    // MARK: - Public Implementation

    func onInterestRateInfoTap() {
        coordinator?.openRateInfoSheet(walletModel: walletModel)
    }

    func onContinueTap() {
        coordinator?.openStartEarningSheet(walletModel: walletModel, startEarnAction: { [weak self] in
            self?.coordinator?.dismiss()
            self?.startEarnAction()
        })
    }

    func onHowItWorksTap() {
        safariManager.openURL(howIrWorksUrl)
    }

    func makeTosAndPrivacyString() -> AttributedString {
        let string = Localization.yieldModulePromoScreenTermsDisclaimer(
            Localization.commonTermsOfUse,
            Localization.commonPrivacyPolicy
        )

        var attributedString = AttributedString(string)
        attributedString.foregroundColor = Colors.Text.tertiary
        attributedString.font = Fonts.Regular.footnote

        if let tosRange = attributedString.range(of: Localization.commonTermsOfUse) {
            attributedString[tosRange].link = tosUrl
            attributedString[tosRange].foregroundColor = Colors.Text.accent
        }

        if let privacyRange = attributedString.range(of: Localization.commonPrivacyPolicy) {
            attributedString[privacyRange].link = privacyPolicyUrl
            attributedString[privacyRange].foregroundColor = Colors.Text.accent
        }

        return attributedString
    }
}
