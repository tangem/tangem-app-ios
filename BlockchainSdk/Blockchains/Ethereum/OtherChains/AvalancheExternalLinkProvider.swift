//
//  AvalancheExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct AvalancheExternalLinkProvider {
    private let isTestnet: Bool
    private let baseURL: String

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
        // The official network explorer ('subnets.avax.network') simply won't load in any browser on iOS 15 and earlier versions
        baseURL = if #available(iOS 16.0, *) {
            "https://subnets.avax.network/c-chain/"
        } else {
            "https://avascan.info/blockchain/c/"
        }
    }
}

extension AvalancheExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://core.app/tools/testnet-faucet/")
    }

    func url(transaction hash: String) -> URL? {
        if isTestnet {
            return URL(string: "https://testnet.avascan.info/blockchain/c/tx/\(hash)")
        }

        return URL(string: baseURL + "tx/\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        if isTestnet {
            return URL(string: "https://testnet.avascan.info/blockchain/c/address/\(address)")
        }

        return URL(string: baseURL + "address/\(address)")
    }
}

// MARK: - NFTExternalLinksProvider

extension AvalancheExternalLinkProvider: NFTExternalLinksProvider {
    func url(tokenAddress: String, tokenID: String, contractType: String) -> URL? {
        URL(string: "https://avascan.info/blockchain/c/\(contractType)/\(tokenAddress)/nft/\(tokenID)")
    }
}
