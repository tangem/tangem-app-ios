//
//  YieldModulePromoV2ViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets

final class YieldModulePromoV2ViewModel {
    // MARK: - Dependencies

    private let walletModel: any WalletModel
    private let availabilityProvider: TokenActionAvailabilityProvider
    private let startFlowFactory: YieldStartFlowFactory
    private weak var coordinator: YieldModulePromoCoordinator?
    private let logger: YieldAnalyticsLogger
    private let percentFormatter = PercentFormatter()

    // MARK: - Properties

    private let apy: Decimal

    let marketIncentive: YieldModuleMarketIncentive?

    var tokenName: String { walletModel.tokenItem.currencySymbol }

    var apyString: String { percentFormatter.format(apy, option: .interval) }

    var incentivisedChipText: String? {
        marketIncentive?.grossRewardsApy.map {
            Localization.yieldModulePromoScreenIncentivisedChip(percentFormatter.format($0, option: .yieldPromo))
        }
    }

    private(set) var tosUrl = URL(string: "https://aave.com/terms-of-service")!
    private(set) var privacyPolicyUrl = URL(string: "https://aave.com/privacy-policy")!
    private(set) var howItWorksUrl = TangemBlogUrlBuilder().url(post: .yieldMode)

    // MARK: - Init

    init(
        walletModel: any WalletModel,
        userWalletInfo: UserWalletInfo,
        apy: Decimal,
        marketIncentive: YieldModuleMarketIncentive?,
        coordinator: YieldModulePromoCoordinator?,
        startFlowFactory: YieldStartFlowFactory,
        logger: YieldAnalyticsLogger
    ) {
        self.walletModel = walletModel
        availabilityProvider = TokenActionAvailabilityProvider(userWalletInfo: userWalletInfo, walletModel: walletModel)
        self.apy = apy
        self.marketIncentive = marketIncentive
        self.coordinator = coordinator
        self.startFlowFactory = startFlowFactory
        self.logger = logger

        logger.logEarningScreenInfoOpened()
    }

    // MARK: - Public Implementation

    func onVariableRateInfoTap() {
        coordinator?.openBottomSheet(viewModel: startFlowFactory.makeInterestRateInfoVewModel())
    }

    func onIncentiveRateInfoTap() {
        coordinator?.openBottomSheet(viewModel: startFlowFactory.makeIncentiveRateInfoViewModel())
    }

    func onContinueTap() {
        if let coordinator {
            logger.logStartEarningScreenOpened()
            coordinator.openBottomSheet(viewModel: startFlowFactory.makeStartViewModel())
        }
    }

    func onHowItWorksTap() {
        coordinator?.openUrl(url: howItWorksUrl)
    }

    func openUrl(_ url: URL) {
        coordinator?.openUrl(url: url)
    }

    var title: String {
        Localization.yieldModulePromoScreenTitleV2(apyString)
    }

    var continueButtonTitle: String {
        switch availabilityProvider.yieldModuleAvailability {
        case .available: Localization.commonContinue
        case .jointAccountsComingSoon: Localization.commonComingSoon
        }
    }

    var isContinueButtonDisabled: Bool {
        !availabilityProvider.isYieldModuleAvailable
    }

    func makeTosAndPrivacyString() -> AttributedString {
        let string = Localization.yieldModulePromoScreenTermsDisclaimer(
            Localization.commonTermsOfUse,
            Localization.commonPrivacyPolicy
        )

        let captionToken = DesignSystem.Font.captionMediumToken

        var attributedString = AttributedString(string)
        attributedString.foregroundColor = DesignSystem.Color.textSecondary
        attributedString.font = captionToken.font
        attributedString.tracking = captionToken.tracking

        if let tosRange = attributedString.range(of: Localization.commonTermsOfUse) {
            attributedString[tosRange].link = tosUrl
            attributedString[tosRange].foregroundColor = DesignSystem.Color.textPrimary
        }

        if let privacyRange = attributedString.range(of: Localization.commonPrivacyPolicy) {
            attributedString[privacyRange].link = privacyPolicyUrl
            attributedString[privacyRange].foregroundColor = DesignSystem.Color.textPrimary
        }

        return attributedString
    }
}
