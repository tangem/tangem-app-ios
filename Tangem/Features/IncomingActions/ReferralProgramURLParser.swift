//
//  ReferralProgramURLParser.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct DeepLinkURLParser: IncomingActionURLParser {
    func parse(_ url: URL) -> IncomingAction? {
        guard url.scheme == "tangem" else { return nil }
        switch url.host {
        case Constants.hostMain:
            return .navigation(.main)

        case Constants.hostToken:
            let tokenName = url.queryValue(named: "symbol") ?? ""
            let network = url.queryValue(named: "network") ?? ""
            return .navigation(.token(tokenName: tokenName, network: network))

        case Constants.hostReferral:
            return .navigation(.referral)

        case Constants.hostBuy:
            return .navigation(.buy)

        case Constants.hostSell:
            return .navigation(.sell)

        case Constants.hostMarkets:
            return .navigation(.markets)

        case Constants.hostTokenChart:
            let tokenName = url.queryValue(named: "symbol") ?? ""
            return .navigation(.tokenChart(tokenName: tokenName))

        case Constants.hostStaking:
            let tokenName = url.queryValue(named: "symbol") ?? ""
            return .navigation(.staking(tokenName: tokenName))

        default:
            return nil
        }
    }
}

private extension DeepLinkURLParser {
    enum Constants {
        static let referralURLString = "tangem://referral"
        static let hostMain = "main"
        static let hostToken = "token"
        static let hostReferral = "referral"
        static let hostBuy = "buy"
        static let hostSell = "sell"
        static let hostMarkets = "markets"
        static let hostTokenChart = "token_chart"
        static let hostStaking = "staking"
    }
}

private extension URL {
    func queryValue(named name: String) -> String? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == name })?
            .value
    }
}
