//
//  CommonTokenFeeProvidersManagerFeeCurrencyBalanceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemExpress
@testable import Tangem

@Suite("CommonTokenFeeProvidersManager — feeCurrencyBalance")
struct CommonTokenFeeProvidersManagerFeeCurrencyBalanceTests {
    private let ethTokenItem: TokenItem = .blockchain(.init(.ethereum(testnet: false), derivationPath: nil))

    @Test("noAccount fee balance is treated as zero")
    func noAccountFeeBalanceIsZero() throws {
        let sut = makeManager(balance: .empty(.noAccount(message: "Account is not created")))

        #expect(try sut.feeCurrencyBalance() == 0)
    }

    @Test("Genuinely unknown fee balances still throw")
    func unknownFeeBalanceThrows() {
        let unknownStates: [TokenBalanceType] = [
            .empty(.noData),
            .loading(nil),
            .failure(nil),
        ]

        for state in unknownStates {
            let sut = makeManager(balance: state)

            #expect(throws: ExpressBalanceProviderError.balanceNotFound) {
                try sut.feeCurrencyBalance()
            }
        }
    }

    @Test("Loaded fee balance is returned as is")
    func loadedFeeBalanceIsReturned() throws {
        let sut = makeManager(balance: .loaded(0.005))

        #expect(try sut.feeCurrencyBalance() == 0.005)
    }

    // MARK: - Helpers

    private func makeManager(balance: TokenBalanceType) -> CommonTokenFeeProvidersManager {
        let provider = ControllableTokenFeeProviderStub(
            feeTokenItem: ethTokenItem,
            balance: balance,
            selectedTokenFee: TokenFee(option: .market, tokenItem: ethTokenItem, value: .loading)
        )

        return CommonTokenFeeProvidersManager(
            feeProviders: [provider],
            initialSelectedProvider: provider,
            ownerAddress: nil
        )
    }
}
