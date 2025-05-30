//
//  DeepLinkURLParser.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct DeepLinkURLParser: IncomingActionURLParser {
    func parse(_ url: URL) -> IncomingAction? {
        guard isValidSchemeAndHost(url) else {
            return nil
        }

        switch url.host {
        case Constants.hostMain:
            return .navigation(.main)

        case Constants.hostToken:
            let tokenName = url.queryValue(named: "token_symbol") ?? ""
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
            let tokenSymbol = url.queryValue(named: "token_symbol") ?? ""
            let tokenId = url.queryValue(named: "token_id") ?? ""
            return .navigation(.tokenChart(tokenSymbol: tokenSymbol, tokenId: tokenId))

        case Constants.hostStaking:
            let tokenName = url.queryValue(named: "token_symbol") ?? ""
            return .navigation(.staking(tokenName: tokenName))

        default:
            return nil
        }
    }

    private func isValidSchemeAndHost(_ url: URL) -> Bool {
        guard url.scheme == Constants.scheme,
              let host = url.host,
              Constants.allHosts.contains(host) else {
            return false
        }
        return true
    }
}

private extension DeepLinkURLParser {
    enum Constants {
        static let scheme = "tangem"

        static let hostMain = "main"
        static let hostToken = "token"
        static let hostReferral = "referral"
        static let hostBuy = "buy"
        static let hostSell = "sell"
        static let hostMarkets = "markets"
        static let hostTokenChart = "token_chart"
        static let hostStaking = "staking"

        static let allHosts: Set<String> = [
            hostMain,
            hostToken,
            hostReferral,
            hostBuy,
            hostSell,
            hostMarkets,
            hostTokenChart,
            hostStaking,
        ]
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
