//
//  HyperliquidExternalLinkProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct HyperliquidExternalLinkProvider {
    private let explorerURL: URL?

    init(isTestnet: Bool) {
        explorerURL = isTestnet ? Constants.explorerURLTestnet : Constants.explorerURL
    }
}

extension HyperliquidExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        nil
    }

    func url(transaction hash: String) -> URL? {
        if #available(iOS 16.0, *) {
            return explorerURL?.appending(path: "tx").appending(path: hash)
        } else {
            return explorerURL?.appendingPathComponent("tx").appendingPathComponent(hash)
        }
    }

    func url(address: String, contractAddress: String?) -> URL? {
        if #available(iOS 16.0, *) {
            return explorerURL?.appending(path: "address").appending(path: address)
        } else {
            return explorerURL?.appendingPathComponent("address").appendingPathComponent(address)
        }
    }
}

private extension HyperliquidExternalLinkProvider {
    enum Constants {
        static let explorerURL = URL(string: "https://hyperevmscan.io")
        static let explorerURLTestnet = URL(string: "https://app.hyperliquid-testnet.xyz/explorer")
    }
}
