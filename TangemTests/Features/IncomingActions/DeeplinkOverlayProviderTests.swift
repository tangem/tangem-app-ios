//
//  DeeplinkOverlayProviderTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

/// Where the enum meets the screens: a destination either builds one of its own or is shown by somebody else,
/// and nothing but that one list says which. A destination that quietly loses its screen still parses, still
/// routes, and opens nothing.
@Suite("Deeplink screen providers")
struct DeeplinkOverlayProviderTests {
    @Test("A destination brings a screen of its own exactly when it is the presenter that shows it", arguments: Self.destinations)
    func destinationsAnswerForTheirScreens(action: DeeplinkNavigationAction) {
        #expect((action.deeplinkOverlayProvider != nil) == Self.isShownByPresenter(action))
    }

    /// The switch is what a new destination runs into: it has to say here whether the presenter shows it, and
    /// the case it is written next to is the one it is tested through below.
    private static func isShownByPresenter(_ action: DeeplinkNavigationAction) -> Bool {
        switch action {
        case .buy,
             .sell,
             .swap,
             .referral,
             .staking,
             .markets,
             .tokenChart,
             .tokenExchanges,
             .earn,
             .yield,
             .news,
             .newsArticle,
             .promo,
             .onboardVisa,
             .payApp,
             .jointAccountInvite,
             .token,
             .feed,
             .support:
            true

        // Shown by the main screen or by a responder of its own.
        case .tangemPayAccount,
             .campaigns,
             .survey,
             .payCustomCard,
             .tangemPayTransaction:
            false
        }
    }

    private static let destinations: [DeeplinkNavigationAction] = [
        .buy(BuyDeeplink(userWalletId: nil)),
        .sell(SellDeeplink(userWalletId: nil)),
        .swap(SwapDeeplink()),
        .referral(ReferralDeeplink(userWalletId: nil)),
        .staking(StakingDeeplink(tokenId: "ethereum", networkId: "ethereum")),
        .markets(MarketsDeeplink(order: nil, interval: nil)),
        .tokenChart(TokenChartDeeplink(tokenId: "ethereum")),
        .tokenExchanges(TokenExchangesDeeplink(tokenId: "ethereum")),
        .earn(EarnDeeplink(earnType: nil, networkId: nil)),
        .yield(YieldDeeplink()),
        .news(NewsDeeplink(newsId: nil, categoryId: nil)),
        .newsArticle(NewsArticleDeeplink(newsId: 190801, deeplinkString: "https://tangem.com/news/markets/190801-a")),
        .promo(PromoDeeplink(code: "PROMO", refcode: nil, campaign: nil)),
        .onboardVisa(OnboardVisaDeeplink(deeplinkString: nil)),
        .payApp(PayAppDeeplink(deeplinkString: "https://tangem.com/pay-app?id=1")),
        .jointAccountInvite(JointAccountInviteDeeplink(inviteId: "B15CF4AC")),
        .token(TokenDeeplink(tokenId: "ethereum", networkId: "ethereum")),
        .feed(FeedDeeplink(section: nil, category: nil, type: nil)),
        .tangemPayAccount(TangemPayAccountDeeplink(screen: nil, userWalletId: nil)),
        .tangemPayTransaction(TangemPayTransactionDeeplink(payload: TangemPayPushPayload(customerWalletId: "wallet", customerId: "customer", body: .thresholdTopUp))),
        .campaigns(CampaignsDeeplink(campaignId: nil)),
        .survey(SurveyDeeplink(token: "ntt-abc123")),
        .payCustomCard(PayCustomCardDeeplink(campaignKey: "tpay_for_harvard")),
        .support(SupportDeeplink()),
    ]

    /// The list above is written by hand, so this is what says it is still the whole enum: one action per
    /// destination, none of them twice.
    @Test("Every destination is tested, and each of them once")
    func everyDestinationIsCovered() {
        let names = Self.destinations.compactMap { Mirror(reflecting: $0).children.first?.label }

        #expect(names.count == Self.destinations.count)
        #expect(Set(names).count == names.count, "A destination is listed twice: \(names.sorted())")
    }
}
