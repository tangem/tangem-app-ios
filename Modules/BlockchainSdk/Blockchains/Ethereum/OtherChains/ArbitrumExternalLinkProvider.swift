//
//  ArbitrumExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct ArbitrumExternalLinkProvider {
    private let isTestnet: Bool
    private let baseURL: String

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
        baseURL = isTestnet ? "https://testnet.arbiscan.io/" : "https://arbiscan.io/"
    }
}

extension ArbitrumExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://nileex.io/join/getJoinPage")
    }

    func url(transaction hash: String) -> URL? {
        if isTestnet {
            return URL(string: "https://testnet.arbiscan.io/tx/\(hash)")
        }

        return URL(string: "https://arbiscan.io/tx/\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        if let contractAddress {
            let url = baseURL + "token/\(contractAddress)?a=\(address)"
            return URL(string: url)
        }

        let url = baseURL + "address/\(address)"
        return URL(string: url)
    }
}

// MARK: - NFTExternalLinksProvider

extension ArbitrumExternalLinkProvider: NFTExternalLinksProvider {
    func url(tokenAddress: String, tokenID: String, contractType: String) -> URL? {
        URL(string: baseURL + "nft/\(tokenAddress)/\(tokenID)")
    }
}
