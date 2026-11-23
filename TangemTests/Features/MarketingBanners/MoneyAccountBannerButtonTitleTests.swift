//
//  MoneyAccountBannerButtonTitleTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemLocalization
@testable import Tangem

@Suite("Money account banner button title", .tags(.marketingBanners))
struct MoneyAccountBannerButtonTitleTests {
    @Test("Without a Money account the onboarding banner asks to activate it")
    func notStartedAccountShowsActivate() {
        let banners = MoneyAccountBannerButtonTitle.applying(to: [Self.onboardingBanner], moneyAccountState: .notStarted)

        #expect(buttonTitle(of: banners[0]) == Localization.commonActivate)
    }

    @Test("While the account state is unknown the button keeps the campaign's text")
    func unknownStateKeepsCampaignText() {
        let states: [TangemPayMoneyAccountState?] = [nil, .loading, .syncNeeded, .unavailable]

        for state in states {
            let banners = MoneyAccountBannerButtonTitle.applying(to: [Self.onboardingBanner], moneyAccountState: state)
            #expect(buttonTitle(of: banners[0]) == "Get account")
        }
    }

    @Test("Only a pseudo-provider banner leading to Money account onboarding gets the account-based text")
    func otherBannersKeepTheirText() {
        let other = Self.banner(id: 2, link: "tangem://onboard-visa?entry=ff1&id=VRTACC01")

        let banners = MoneyAccountBannerButtonTitle.applying(to: [other, Self.onboardingBanner], moneyAccountState: .notStarted)

        #expect(buttonTitle(of: banners[0]) == "Get account")
        #expect(buttonTitle(of: banners[1]) == Localization.commonActivate)
    }
}

// MARK: - Helpers

private extension MoneyAccountBannerButtonTitleTests {
    static let onboardingBanner = banner(id: 1, link: "tangem://onboard-virtual-account?entry=ff1&id=VRTACC01")

    static func banner(id: Int, link: String) -> CallToActionMarketingBanner {
        .pseudoProvider(CallToActionMarketingBannerViewModel(
            id: id,
            title: "USD account",
            buttonTitle: "Get account",
            isGlowing: false,
            link: URL(string: link)!,
            isDismissible: false,
            content: .init(categoryLabel: nil, subtitle: nil, etaLabel: nil, partnerLabel: nil, replacedSlot: .greatRate)
        ))
    }

    func buttonTitle(of banner: CallToActionMarketingBanner) -> String? {
        if case .pseudoProvider(let viewModel) = banner {
            return viewModel.buttonTitle
        }

        return nil
    }
}
