//
//  TerraV1ExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct TerraV1ExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? { nil }

    func url(transaction hash: String) -> URL? {
        URL(string: "https://finder.terra-classic.hexxagon.io/mainnet/tx/\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        URL(string: "https://finder.terra-classic.hexxagon.io/mainnet/address/\(address)")
    }
}
