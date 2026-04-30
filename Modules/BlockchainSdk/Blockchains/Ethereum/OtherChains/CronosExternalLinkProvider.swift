//
//  CronosExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct CronosExternalLinkProvider: ExternalLinkProvider {
    let baseURL = "https://cronoscan.com/"

    var testnetFaucetURL: URL? { nil }

    func url(transaction hash: String) -> URL? {
        return URL(string: "https://cronoscan.com/tx/\(hash)")
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

extension CronosExternalLinkProvider: NFTExternalLinksProvider {
    func url(tokenAddress: String, tokenID: String, contractType: String) -> URL? {
        URL(string: baseURL + "nft/\(tokenAddress)/\(tokenID)")
    }
}
