//
//  BSCExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct BSCExternalLinkProvider {
    private let isTestnet: Bool
    private let baseURL: String

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
        baseURL = isTestnet ? "https://testnet.bscscan.com/" : "https://bscscan.com/"
    }
}

extension BSCExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://testnet.binance.org/faucet-smart")
    }

    func url(transaction hash: String) -> URL? {
        if isTestnet {
            return URL(string: "https://testnet.bscscan.com/tx/\(hash)")
        }

        return URL(string: "https://bscscan.com/tx/\(hash)")
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

extension BSCExternalLinkProvider: NFTExternalLinksProvider {
    func url(tokenAddress: String, tokenID: String, contractType: String) -> URL? {
        URL(string: baseURL + "nft/\(tokenAddress)/\(tokenID)")
    }
}
