//
//  TangemPayBalanceNetworksFixture.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPay

/// Decodes a `networks` array the way the balance endpoint sends it, so a test can state its
/// fixture as the payload rather than as already-parsed models.
func makeTangemPayNetworks(_ json: String) throws -> [TangemPayBalance.Network] {
    let balanceJSON = """
    {
      "fiat": {
        "currency": "USD",
        "availableBalance": 0,
        "creditLimit": 0,
        "pendingCharges": 0,
        "postedCharges": 0,
        "balanceDue": 0
      },
      "crypto": {
        "id": "usd-coin",
        "chainId": 137,
        "depositAddress": "0xdeposit",
        "tokenContractAddress": "0xusdc",
        "balance": 0
      },
      "availableForWithdrawal": { "amount": 0, "currency": "USD" },
      "networks": \(json)
    }
    """

    return try JSONDecoder().decode(TangemPayBalance.self, from: Data(balanceJSON.utf8)).networks
}
