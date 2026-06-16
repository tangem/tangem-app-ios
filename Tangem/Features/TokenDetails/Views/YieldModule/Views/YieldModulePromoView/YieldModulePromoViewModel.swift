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
    private static let apyBoostMultiplier: Decimal = 3

    // MARK: - Dependencies

    private let walletModel: any WalletModel
    private let yieldManagerInteractor: YieldManagerInteractor
    private let startFlowFactory: YieldStartFlowFactory
    private weak var coordinator: YieldModulePromoCoordinator?
    private let logger: YieldAnalyticsLogger

    // MARK: - Properties

    private let apy: Decimal
    let isApyBoostPromo: Bool
    var tokenName: String { walletModel.tokenItem.currencySymbol }

    var apyString: String { PercentFormatter().format(apy, option: .interval) }
    private(set) var tosUrl = URL(string: "https://aave.com/terms-of-service")!
    private(set) var privacyPolicyUrl = URL(string: "https://aave.com/privacy-policy")!
    private(set) var howIrWorksUrl = TangemBlogUrlBuilder().url(post: .yieldMode)
    private(set) var apyBoostPromoTerms = URL(string: "https://tangem.com/docs/en/yield-mode-terms.pdf")!
    private static let apyBoostLearnMoreLink = URL(string: "yield-apy-boost-promo://learn-more")!

    // MARK: - Init

    init(
        walletModel: any WalletModel,
        yieldManagerInteractor: YieldManagerInteractor,
        apy: Decimal,
        isApyBoostPromo: Bool,
        coordinator: YieldModulePromoCoordinator?,
        startFlowFactory: YieldStartFlowFactory,
        logger: YieldAnalyticsLogger
    ) {
        self.walletModel = walletModel
        self.coordinator = coordinator
        self.yieldManagerInteractor = yieldManagerInteractor
        self.apy = apy
        self.isApyBoostPromo = isApyBoostPromo
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

    func makeTitleString() -> AttributedString {
        if isApyBoostPromo {
            return makeApyBoostTitle()
        }
        return styled(
            Localization.yieldModulePromoScreenTitleV2(apyString),
            font: Fonts.Bold.title1,
            color: Colors.Text.primary1
        )
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

    func makeApyBoostTitle() -> AttributedString {
        let template = Localization.yieldModulePromoScreenTitleV2(apyString).replacingOccurrences(of: "%", with: "")
        let font = Fonts.Bold.title2
        let boostedApyString = PercentFormatter().format(apy * Self.apyBoostMultiplier, option: .yieldPromo)

        var attributed = styled(template, font: font, color: Colors.Text.primary1)

        guard let range = attributed.range(of: apyString) else {
            return attributed
        }

        let strikethroughApy = styled(
            PercentFormatter().format(apy, option: .yieldPromo),
            font: font,
            color: Colors.Text.accent,
            strikethrough: true
        )
        let arrowAndBoostedApy = styled(" → \(boostedApyString)", font: font, color: Colors.Text.accent)

        attributed.replaceSubrange(range, with: strikethroughApy + arrowAndBoostedApy)
        return attributed
    }

    func makeApyBoostBlockTitleString() -> AttributedString {
        let bold = Fonts.Bold.subheadline
        let regular = Fonts.Regular.subheadline
        let accent = Colors.Text.accent
        let boostedApyString = PercentFormatter().format(apy * Self.apyBoostMultiplier, option: .yieldPromo)

        return styled(Localization.commonYieldMode, font: bold, color: Colors.Text.primary1)
            + styled(" \(AppConstants.dotSign) ", font: regular, color: Colors.Text.tertiary)
            + styled(Localization.yieldModuleTokenDetailsEarnNotificationApy + " ", font: bold, color: accent)
            + styled(PercentFormatter().format(apy, option: .yieldPromo), font: bold, color: accent, strikethrough: true)
            + styled(" x\(Self.apyBoostMultiplier) → \(boostedApyString)", font: bold, color: accent)
    }

    func makeApyBoostEligibilityString() -> AttributedString {
        let learnMoreText = Localization.commonLearnMore.lowercased()
        let termsText = Localization.yieldApyBoostPromoTermsAndConditions
        let fullText = "\(Localization.yieldApyBoostPromoEligibilityText) \(learnMoreText) \(termsText)"

        var attributed = styled(fullText, font: Fonts.Regular.footnote, color: Colors.Text.tertiary)

        if let learnMoreRange = attributed.range(of: learnMoreText) {
            attributed[learnMoreRange].link = Self.apyBoostLearnMoreLink
            attributed[learnMoreRange].foregroundColor = Colors.Text.accent
        }

        if let termsRange = attributed.range(of: termsText) {
            attributed[termsRange].link = apyBoostPromoTerms
            attributed[termsRange].foregroundColor = Colors.Text.accent
        }

        return attributed
    }

    func onApyBoostEligibilityLinkTap(_ url: URL) {
        if url == Self.apyBoostLearnMoreLink {
            coordinator?.openYieldApyBoostStory()
        } else {
            openUrl(url)
        }
    }
}

// MARK: - AttributedString builders

private extension YieldModulePromoViewModel {
    func styled(
        _ string: String,
        font: Font,
        color: Color,
        strikethrough: Bool = false
    ) -> AttributedString {
        var attributed = AttributedString(string)
        attributed.font = font
        attributed.foregroundColor = color
        if strikethrough {
            attributed.strikethroughStyle = .single
        }
        return attributed
    }
}
