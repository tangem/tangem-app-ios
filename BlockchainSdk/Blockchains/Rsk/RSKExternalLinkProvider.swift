//
//  RSKExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct RSKExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? { nil }
    
    func url(transaction hash: String) -> URL? {
        return URL(string: "https://explorer.rsk.co/tx/\(hash)")
    }
    
    func url(address: String, contractAddress: String?) -> URL? {
        var exploreLink = "https://explorer.rsk.co/address/\(address)"
        if contractAddress != nil {
            exploreLink += "?__tab=tokens"
        }
        return URL(string: exploreLink)
    }
}
