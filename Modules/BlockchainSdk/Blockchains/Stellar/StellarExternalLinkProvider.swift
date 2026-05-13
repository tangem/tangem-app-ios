//
//  StellarExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct StellarExternalLinkProvider {
    private let isTestnet: Bool

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

extension StellarExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://laboratory.stellar.org/#account-creator?network=test")
    }

    func url(transaction hash: String) -> URL? {
        if isTestnet {
            return URL(string: "https://testnet.stellarchain.io/transactions/\(hash)")
        }

        return URL(string: "https://stellarchain.io/transactions/\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        if isTestnet {
            return URL(string: "https://testnet.stellarchain.io/accounts/\(address)")
        }

        return URL(string: "https://stellarchain.io/accounts/\(address)")
    }
}
