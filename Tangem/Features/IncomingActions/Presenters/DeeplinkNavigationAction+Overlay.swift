//
//  DeeplinkNavigationAction+Overlay.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension DeeplinkNavigationAction {
    /// The destination this action carries, as the thing that knows how to show itself over the current screen.
    /// This is the one place where the two halves meet: a line per case, and the compiler keeps the list complete.
    var deeplinkOverlayProvider: (any DeeplinkOverlayProviding)? {
        switch self {
        case .buy(let deeplink): deeplink
        case .sell(let deeplink): deeplink
        case .swap(let deeplink): deeplink
        case .referral(let deeplink): deeplink
        case .staking(let deeplink): deeplink
        case .markets(let deeplink): deeplink
        case .tokenChart(let deeplink): deeplink
        case .tokenExchanges(let deeplink): deeplink
        case .earn(let deeplink): deeplink
        case .yield(let deeplink): deeplink
        case .news(let deeplink): deeplink
        case .newsArticle(let deeplink): deeplink
        case .promo(let deeplink): deeplink
        case .onboardVisa(let deeplink): deeplink
        case .payApp(let deeplink): deeplink
        case .jointAccountInvite(let deeplink): deeplink
        case .token(let deeplink): deeplink
        case .support(let deeplink): deeplink
        // Shown by whoever owns them: the payment account and the co-brand campaign from the main screen,
        // campaigns, the survey and a payment transaction by responders of their own.
        case .tangemPayAccount, .campaigns, .survey, .payCustomCard, .tangemPayTransaction: nil
        }
    }
}
