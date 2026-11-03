//
//  E2ENetwork.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct E2ENetwork {
    let coinId: String
    let searchQuery: String
    let tokenName: String
    let networkName: String
    let mainScreenToken: String
    /// The wallet's per-account receive addresses for this network, ordered by account index (sender/recipient
    /// for the Send E2E test).
    let accountAddresses: [String]
}

struct E2ETestData {
    let seedPhrase: String
    let walletId: String
    let network: E2ENetwork
}
