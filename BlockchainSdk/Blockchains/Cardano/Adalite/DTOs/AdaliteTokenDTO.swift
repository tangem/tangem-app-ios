//
//  AdaliteTokenDTO.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

struct AdaliteTokenDTO: Decodable {
    let assetName: String
    let quantity: String
    let policyId: String
}
