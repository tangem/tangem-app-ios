//
//  TerraV2ExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct TerraV2ExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? { nil }
    
    func url(transaction hash: String) -> URL? {
        return URL(string: "https://terrasco.pe/mainnet/tx/\(hash)")
    }
    
    func url(address: String, contractAddress: String?) -> URL? {
        return URL(string: "https://terrasco.pe/mainnet/address/\(address)")
    }
}
