//
//  DeeplinkNavigationAction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum DeeplinkNavigationAction: Equatable {
    case token(TokenDeeplink)
    case staking(StakingDeeplink)
    case yield(YieldDeeplink)
    case swap(SwapDeeplink)
    case markets(MarketsDeeplink)
    case feed(FeedDeeplink)
    case buy(BuyDeeplink)
    case sell(SellDeeplink)
    case referral(ReferralDeeplink)
    case promo(PromoDeeplink)
    case news(NewsDeeplink)
    case newsArticle(NewsArticleDeeplink)
    case earn(EarnDeeplink)
    case tangemPayAccount(TangemPayAccountDeeplink)
    case tokenChart(TokenChartDeeplink)
    case tokenExchanges(TokenExchangesDeeplink)
    case survey(SurveyDeeplink)
    case campaigns(CampaignsDeeplink)
    case onboardVisa(OnboardVisaDeeplink)
    case payApp(PayAppDeeplink)
    case jointAccountInvite(JointAccountInviteDeeplink)
    case jointAccount(JointAccountDeeplink)
    case payCustomCard(PayCustomCardDeeplink)
    case support(SupportDeeplink)
    case tangemPayTransaction(TangemPayTransactionDeeplink)
}

// MARK: - Identity

extension DeeplinkNavigationAction {
    /// Identity by value: the same link asked for twice is the same screen, and a link that differs in a single
    /// parameter is a different one. Reflection keeps this free — a new destination needs no line here.
    var id: String {
        String(describing: self)
    }
}

// MARK: - Parsing

extension DeeplinkNavigationAction {
    /// Reads the link. `nil` means it names no destination of ours, or it doesn't carry what the one it names
    /// needs — either way it never becomes a navigation action.
    init?(link: DeeplinkURL) {
        let action: DeeplinkNavigationAction?

        switch link.kind {
        case .host(let host):
            action = try? Self.destinationsNamedByHost[host]?.init(link: link).action

        case .path(_, let components):
            let destination = components.first.flatMap { Self.destinationsNamedByPath[$0.lowercased()] }
            action = destination?.action(from: link)
        }

        guard let action else {
            return nil
        }

        self = action
    }

    /// Keyed by the host, so nothing can be reached by a name it doesn't declare and two destinations can't
    /// quietly claim the same one.
    static let destinationsNamedByHost: [String: any HostNamedDeeplink.Type] = [
        TokenDeeplink.host: TokenDeeplink.self,
        StakingDeeplink.host: StakingDeeplink.self,
        YieldDeeplink.host: YieldDeeplink.self,
        SwapDeeplink.host: SwapDeeplink.self,
        MarketsDeeplink.host: MarketsDeeplink.self,
        FeedDeeplink.host: FeedDeeplink.self,
        BuyDeeplink.host: BuyDeeplink.self,
        SellDeeplink.host: SellDeeplink.self,
        ReferralDeeplink.host: ReferralDeeplink.self,
        PromoDeeplink.host: PromoDeeplink.self,
        NewsDeeplink.host: NewsDeeplink.self,
        EarnDeeplink.host: EarnDeeplink.self,
        TangemPayAccountDeeplink.host: TangemPayAccountDeeplink.self,
        TokenChartDeeplink.host: TokenChartDeeplink.self,
        TokenExchangesDeeplink.host: TokenExchangesDeeplink.self,
        SurveyDeeplink.host: SurveyDeeplink.self,
        CampaignsDeeplink.host: CampaignsDeeplink.self,
        OnboardVisaDeeplink.host: OnboardVisaDeeplink.self,
        PayAppDeeplink.host: PayAppDeeplink.self,
        JointAccountInviteDeeplink.host: JointAccountInviteDeeplink.self,
        JointAccountDeeplink.host: JointAccountDeeplink.self,
        SupportDeeplink.host: SupportDeeplink.self,
    ]

    /// Keyed by the first component of the path for the same reason. The rest of the shape is each
    /// destination's own business. A destination named by a host as well appears in both lists.
    static let destinationsNamedByPath: [String: any PathNamedDeeplink.Type] = [
        PayAppDeeplink.pathSegment: PayAppDeeplink.self,
        NewsArticleDeeplink.pathSegment: NewsArticleDeeplink.self,
        JointAccountInviteDeeplink.pathSegment: JointAccountInviteDeeplink.self,
    ]
}
