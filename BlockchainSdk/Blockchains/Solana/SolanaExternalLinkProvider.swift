//
//  SolanaExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct SolanaExternalLinkProvider {
    private let isTestnet: Bool
    private let baseURL: String

    init(isTestnet: Bool) {
        baseURL = "https://explorer.solana.com/address/"
        self.isTestnet = isTestnet
    }
}

extension SolanaExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://solfaucet.com")
    }

    func url(transaction hash: String) -> URL? {
        if isTestnet {
            return URL(string: "https://explorer.solana.com/tx/\(hash)?cluster=devnet")
        }

        return URL(string: "https://explorer.solana.com/tx/\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        let cluster = isTestnet ? "?cluster=devnet" : ""
        var exploreLink = baseURL + address + cluster

        if contractAddress != nil {
            exploreLink += "/tokens"
        }

        return URL(string: exploreLink)
    }

    func nftURL(tokenAddress: String, tokenID: String) -> URL? {
        URL(string: baseURL + tokenAddress)
    }
}
