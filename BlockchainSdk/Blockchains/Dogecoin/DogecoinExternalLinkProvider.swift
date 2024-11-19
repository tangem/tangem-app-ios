//
//  DogecoinExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct DogecoinExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? { nil }

    func url(transaction hash: String) -> URL? {
        return URL(string: "https://blockchair.com/dogecoin/transaction/\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        return URL(string: "https://blockchair.com/dogecoin/address/\(address)")
    }
}
