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
    // MARK: - Dependencies

    private let walletModel: any WalletModel
    private let yieldManagerInteractor: YieldManagerInteractor
    private let startFlowFactory: YieldStartFlowFactory
    private weak var coordinator: YieldModulePromoCoordinator?
    private let logger: YieldAnalyticsLogger

    // MARK: - Properties

    private let apy: Decimal
    var tokenName: String { walletModel.tokenItem.currencySymbol }
    var apyString: String { PercentFormatter().format(apy, option: .interval) }
    private(set) var tosUrl = URL(string: "https://aave.com/terms-of-service")!
    private(set) var privacyPolicyUrl = URL(string: "https://aave.com/privacy-policy")!
    private(set) var howIrWorksUrl = URL(string: "https://tangem.com/en/blog/post/yield-mode")!

    // MARK: - Init

    init(
        walletModel: any WalletModel,
        yieldManagerInteractor: YieldManagerInteractor,
        apy: Decimal,
        coordinator: YieldModulePromoCoordinator?,
        startFlowFactory: YieldStartFlowFactory,
        logger: YieldAnalyticsLogger
    ) {
        self.walletModel = walletModel
        self.coordinator = coordinator
        self.yieldManagerInteractor = yieldManagerInteractor
        self.apy = apy
        self.startFlowFactory = startFlowFactory
        self.logger = logger

        logger.logEarningScreenInfoOpened()
    }

    // MARK: - Public Implementation

    func onInterestRateInfoTap() {
        coordinator?.openBottomSheet(viewModel: startFlowFactory.makeInterestRateInfoVewModel())
    }

    func onContinueTap() {
        if let coordinator {
            logger.logStartEarningScreenOpened()
            coordinator.openBottomSheet(viewModel: startFlowFactory.makeStartViewModel())
        }
    }

    func onHowItWorksTap() {
        coordinator?.openUrl(url: howIrWorksUrl)
    }

    func openUrl(_ url: URL) {
        coordinator?.openUrl(url: url)
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
