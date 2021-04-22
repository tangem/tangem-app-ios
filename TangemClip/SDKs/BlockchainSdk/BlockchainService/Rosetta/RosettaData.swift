//
//  RosettaData.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

struct RosettaNetworkIdentifier: Codable {
    let blockchain: String
    let network: String
    
    static let mainNet = RosettaNetworkIdentifier(blockchain: "cardano", network: "mainnet")
}

struct RosettaAccountIdentifier: Codable {
    let address: String
}

struct RosettaAmount: Codable {
    let value: String?
    let currency: RosettaCurrency?
    
    var valueDecimal: Decimal? {
        Decimal(value)
    }
}

struct RosettaCurrency: Codable {
    let symbol: String?
    let decimals: Int?
}

struct RosettaCoin: Codable {
    let coinIdentifier: RosettaCoinIdentifier?
    let amount: RosettaAmount?
}

struct RosettaCoinIdentifier: Codable {
    let identifier: String?
}

struct RosettaTransactionIdentifier: Codable {
    let hash: String?
}
