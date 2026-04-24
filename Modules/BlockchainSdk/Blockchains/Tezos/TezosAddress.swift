//
//  TezosResponse.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

struct TezosAddressResponse: Codable {
    let balance: String?
    let counter: String?
}

struct TezosHeaderResponse: Codable {
    let `protocol`: String?
    let hash: String?
}

struct TezosAddress {
    let balance: Decimal
    let counter: Int
    let isPublicKeyRevealed: Bool
}

struct TezosHeader: Codable {
    let `protocol`: String
    let hash: String
}
