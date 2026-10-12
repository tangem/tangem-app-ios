//
//  Analytics+Stories.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

extension Analytics {
    enum StoriesSource: String {
        case main = "Main"
        case tokenListContextMenu = "Long Tap"
        case token = "Token"
        case markets = "Markets"
        case predictions = "Predictions"
        case walletSettings = "Wallet Settings"
        case tangemPay = "Tangem Pay"
        case onboarding = "Onboarding"
        case collectibles = "Collectibles"
    }

    enum StoryType: String {
        case swap = "Swap"
        case yieldFirstActivationAPYBoost = "Yield First Activation APY Boost"
        case polymarketOnboarding = "Polymarket Onboarding"
    }
}
