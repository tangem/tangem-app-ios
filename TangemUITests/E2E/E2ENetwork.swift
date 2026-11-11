//
//  E2ENetwork.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct E2EToken {
    let coinId: String
    let searchQuery: String
    let tokenName: String
    let mainScreenToken: String
    let contractAddress: String
    let sendAmount: String
}

struct E2ENetwork {
    let coinId: String
    let searchQuery: String
    let tokenName: String
    let networkName: String
    let mainScreenToken: String
    let accountAddresses: [String]
    let token: E2EToken?
}

struct E2ETestData {
    let seedPhrase: String
    let walletId: String
    let network: E2ENetwork
}
