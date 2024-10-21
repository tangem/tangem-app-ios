//
//  KusamaExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct KusamaExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? { nil }
    
    func url(transaction hash: String) -> URL? {
        return URL(string: "https://kusama.subscan.io/extrinsic/\(hash)")
    }
    
    func url(address: String, contractAddress: String?) -> URL? {
        return URL(string: "https://kusama.subscan.io/account/\(address)")
    }
}
