//
//  GnosisExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct GnosisExternalLinkProvider: ExternalLinkProvider {
    let baseURL = "https://gnosis.blockscout.com/"

    var testnetFaucetURL: URL? { nil }

    func url(transaction hash: String) -> URL? {
        return URL(string: baseURL + "tx/\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        return URL(string: baseURL + "address/\(address)")
    }
}

// MARK: - NFTExternalLinksProvider

extension GnosisExternalLinkProvider: NFTExternalLinksProvider {
    func url(tokenAddress: String, tokenID: String, contractType: String) -> URL? {
        URL(string: "https://gnosisscan.io/token/\(tokenAddress)/\(tokenID)")
    }
}
