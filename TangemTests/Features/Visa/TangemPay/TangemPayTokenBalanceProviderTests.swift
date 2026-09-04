//
//  TangemPayTokenBalanceProviderTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import Foundation
import Testing
import TangemFoundation
import TangemPay
@testable import Tangem

@Suite("TangemPayTokenBalanceProvider")
struct TangemPayTokenBalanceProviderTests {
    @Test("A provider nobody retains keeps delivering while its balance publisher is subscribed")
    func subscriptionKeepsTheProviderAlive() throws {
        let balanceSubject = CurrentValueSubject<LoadingResult<TangemPayBalance, Error>?, Never>(.loading)
        let received = OSAllocatedUnfairLock(initialState: [TokenBalanceType]())

        // A selector row keeps the publisher and drops the provider it came from.
        let cancellable = makeProvider(balanceSubject: balanceSubject)
            .balanceTypePublisher
            .sink { balanceType in received.withLock { $0.append(balanceType) } }

        balanceSubject.send(.success(try makeBalance(availableForWithdrawal: 12.5)))

        #expect(received.withLock { $0.last } == .loaded(12.5))
        cancellable.cancel()
    }

    @Test("The formatted publisher survives the same way")
    func formattedSubscriptionKeepsTheProviderAlive() throws {
        let balanceSubject = CurrentValueSubject<LoadingResult<TangemPayBalance, Error>?, Never>(.loading)
        let received = OSAllocatedUnfairLock(initialState: [FormattedTokenBalanceType]())

        let cancellable = makeProvider(balanceSubject: balanceSubject)
            .formattedBalanceTypePublisher
            .sink { balanceType in received.withLock { $0.append(balanceType) } }

        balanceSubject.send(.success(try makeBalance(availableForWithdrawal: 12.5)))

        // The subject replays `.loading` on subscription, so only a second emission proves
        // the provider outlived the statement that built it.
        #expect(received.withLock { $0.count } == 2)
        #expect(received.withLock { $0.last?.isLoading } == false)
        cancellable.cancel()
    }

    // MARK: - Helpers

    private static let chainId = 137
    private static let contractAddress = "0x3c499c542cef5e3811e1192ce70d8cc03d5c3359"

    private func makeProvider(
        balanceSubject: CurrentValueSubject<LoadingResult<TangemPayBalance, Error>?, Never>
    ) -> TangemPayTokenBalanceProvider {
        TangemPayTokenBalanceProvider(
            tokenItem: TangemPayUtilities.usdcTokenItem,
            tokenBalancesRepository: TokenBalancesRepositoryMock(),
            balanceSubject: balanceSubject,
            value: {
                $0.availableForWithdrawal(chainId: Self.chainId, tokenContractAddress: Self.contractAddress) ?? .zero
            },
            cachesBalance: false
        )
    }

    private func makeBalance(availableForWithdrawal: Decimal) throws -> TangemPayBalance {
        let json = """
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
            "chainId": \(Self.chainId),
            "depositAddress": "0xdeposit",
            "tokenContractAddress": "\(Self.contractAddress)",
            "balance": 0
          },
          "availableForWithdrawal": { "amount": 0, "currency": "USD" },
          "networks": [
            {
              "name": "\(Blockchain.polygon(testnet: false).networkId)",
              "isTestnet": false,
              "chainId": \(Self.chainId),
              "status": "ENABLED",
              "depositAddress": "0xdeposit",
              "tokens": [
                {
                  "token": "USDC",
                  "tokenContractAddress": "\(Self.contractAddress)",
                  "availableForWithdrawal": \(availableForWithdrawal)
                }
              ]
            }
          ]
        }
        """

        return try JSONDecoder().decode(TangemPayBalance.self, from: Data(json.utf8))
    }
}
