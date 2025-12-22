//
//  HyperliquidExternalLinkProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

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
        explorerURL?.appending(path: "tx").appending(path: hash)
    }

    func url(address: String, contractAddress: String?) -> URL? {
        explorerURL?.appending(path: "address").appending(path: address)
    }
}

private extension HyperliquidExternalLinkProvider {
    enum Constants {
        static let explorerURL = URL(string: "https://hyperevmscan.io")
        static let explorerURLTestnet = URL(string: "https://app.hyperliquid-testnet.xyz/explorer")
    }
}
