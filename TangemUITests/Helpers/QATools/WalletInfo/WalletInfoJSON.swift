//
//  WalletInfoJSON.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct AddressesResponse: Codable {
    let data: [WalletInfoJSON]
}

struct WalletInfoJSON: Codable {
    let addresses: [String]
    let blockchain: String
    let derivationPath: String
    let token: String?

    enum CodingKeys: String, CodingKey {
        case addresses
        case blockchain
        case derivationPath
        case token
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(addresses, forKey: .addresses)
        try container.encode(blockchain, forKey: .blockchain)
        try container.encode(derivationPath, forKey: .derivationPath)

        if let token = token, !token.isEmpty {
            try container.encode(token, forKey: .token)
        }
    }
}
