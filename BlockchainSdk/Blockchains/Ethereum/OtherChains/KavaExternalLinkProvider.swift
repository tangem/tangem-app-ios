//
//  KavaExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct KavaExternalLinkProvider {
    private let isTestnet: Bool

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

extension KavaExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://faucet.kava.io")!
    }

    func url(transaction hash: String) -> URL? {
        if isTestnet {
            return URL(string: "https://explorer.testnet.kava.io/tx/\(hash)")
        }

        return URL(string: "https://kavascan.com/tx/\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        if isTestnet {
            return URL(string: "https://explorer.testnet.kava.io/address/\(address)")
        }

        return URL(string: "https://kavascan.com/address/\(address)")
    }
}
