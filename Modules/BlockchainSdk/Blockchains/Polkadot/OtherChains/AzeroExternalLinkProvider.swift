//
//  AzeroExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct AzeroExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://faucet.test.azero.dev")
    }

    func url(transaction hash: String) -> URL? {
        return URL(string: "https://alephzero-lite.subscan.io/sub/extrinsic/\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        return URL(string: "https://alephzero-lite.subscan.io/sub/account/\(address)")
    }
}
