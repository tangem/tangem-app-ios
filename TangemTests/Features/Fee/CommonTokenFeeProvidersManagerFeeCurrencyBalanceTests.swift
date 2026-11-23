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

    @Test("The fee is sponsored only when the selected provider is paid by Tangem", arguments: [TokenFeePayer.user, .tangem])
    func feeIsSponsoredByPayer(payer: TokenFeePayer) {
        let sut = makeManager(balance: .loaded(0), payer: payer)

        #expect(sut.isFeeSponsored == (payer == .tangem))
    }

    // MARK: - Helpers

    private func makeManager(balance: TokenBalanceType, payer: TokenFeePayer = .user) -> CommonTokenFeeProvidersManager {
        let provider = ControllableTokenFeeProviderStub(
            feeTokenItem: ethTokenItem,
            payer: payer,
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
