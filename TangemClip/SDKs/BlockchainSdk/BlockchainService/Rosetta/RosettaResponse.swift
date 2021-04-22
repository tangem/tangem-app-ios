//
//  RosettaResponse.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

struct RosettaBalanceResponse: Codable {
    let balances: [RosettaAmount]
    let coins: [RosettaCoin]?
    
    var address: String?
}

struct RosettaSubmitResponse: Codable {
    let transactionIdentifier: RosettaTransactionIdentifier
}
