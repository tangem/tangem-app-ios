//
//  TangemPayBalanceWithdrawableLookupTests.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemPay

@Suite("TangemPayBalance per-network withdrawable lookup")
struct TangemPayBalanceWithdrawableLookupTests {
    @Test("the amount is found by chain id and contract")
    func findsAmountByChainIdAndContract() throws {
        let balance = try makeBalance()

        #expect(balance.availableForWithdrawal(chainId: 8453, tokenContractAddress: "0xBaseUSDC") == 7)
    }

    @Test("the contract address is matched case-insensitively")
    func matchesContractCaseInsensitively() throws {
        let balance = try makeBalance()

        #expect(balance.availableForWithdrawal(chainId: 137, tokenContractAddress: "0XPOLYGONUSDC") == 5)
    }

    @Test("an unknown network yields nil")
    func unknownNetworkYieldsNil() throws {
        let balance = try makeBalance()

        #expect(balance.availableForWithdrawal(chainId: 1, tokenContractAddress: "0xBaseUSDC") == nil)
    }

    @Test("an unknown contract on a known network yields nil")
    func unknownContractYieldsNil() throws {
        let balance = try makeBalance()

        #expect(balance.availableForWithdrawal(chainId: 8453, tokenContractAddress: "0xSomethingElse") == nil)
    }

    @Test("a held token without a withdrawable amount yields nil")
    func missingAmountYieldsNil() throws {
        let balance = try makeBalance()

        #expect(balance.availableForWithdrawal(chainId: 137, tokenContractAddress: "0xPolygonUSDT") == nil)
    }

    // MARK: - Helpers

    /// `TangemPayBalance` only decodes (no memberwise init), so the fixture goes through JSON.
    private func makeBalance() throws -> TangemPayBalance {
        let json = """
        {
          "fiat": {
            "currency": "USD",
            "availableBalance": 12,
            "creditLimit": 0,
            "pendingCharges": 0,
            "postedCharges": 0,
            "balanceDue": 0
          },
          "crypto": {
            "id": "usdc",
            "chainId": 137,
            "depositAddress": "0xDEPOSIT",
            "tokenContractAddress": "0xPolygonUSDC",
            "balance": 12
          },
          "availableForWithdrawal": {
            "amount": 12,
            "currency": "USD"
          },
          "networks": [
            {
              "name": "polygon",
              "isTestnet": false,
              "chainId": 137,
              "status": "ENABLED",
              "depositAddress": "0xDEPOSIT",
              "tokens": [
                {
                  "token": "USDC",
                  "tokenContractAddress": "0xPolygonUSDC",
                  "availableForWithdrawal": 5
                },
                {
                  "token": "USDT",
                  "tokenContractAddress": "0xPolygonUSDT"
                }
              ]
            },
            {
              "name": "base",
              "isTestnet": false,
              "chainId": 8453,
              "status": "ENABLED",
              "depositAddress": "0xDEPOSIT",
              "tokens": [
                {
                  "token": "USDC",
                  "tokenContractAddress": "0xBaseUSDC",
                  "availableForWithdrawal": 7
                }
              ]
            }
          ]
        }
        """

        return try JSONDecoder().decode(TangemPayBalance.self, from: Data(json.utf8))
    }
}
