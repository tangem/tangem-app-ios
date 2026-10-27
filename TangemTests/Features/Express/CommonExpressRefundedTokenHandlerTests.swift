//
//  CommonExpressRefundedTokenHandlerTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemExpress
import TangemFoundation
@testable import Tangem

extension TransactionHistoryAuxDataRepositoryDependentTests {
    @Suite("CommonExpressRefundedTokenHandler")
    struct CommonExpressRefundedTokenHandlerTests {
        @Test("The refunded token is still reported when it can't be added to the source wallet")
        func reportsRefundedTokenWhenSourceWalletIsUnavailable() async throws {
            let ethereum = BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil)
            let contractAddress = "0xdac17f958d2ee523a2206206994597c13d831ec7"
            let usdt = TokenItem.token(
                .init(name: "Tether", symbol: "USDT", contractAddress: contractAddress, decimalCount: 6, id: "tether"),
                ethereum
            )
            let currency = ExpressCurrency(contractAddress: contractAddress, network: ethereum.blockchain.networkId)
            let auxDataRepository = TransactionHistoryAuxDataRepositoryStub()
            auxDataRepository.register(usdt, for: currency)

            let refundedToken = try await InjectedDependenciesIsolation.shared.run {
                let previousAuxDataRepository = InjectedValues[\.transactionHistoryAuxDataRepository]
                let previousUserWalletRepository = InjectedValues[\.userWalletRepository]
                InjectedValues[\.transactionHistoryAuxDataRepository] = auxDataRepository
                InjectedValues[\.userWalletRepository] = FakeUserWalletRepository(models: [])
                defer {
                    InjectedValues[\.transactionHistoryAuxDataRepository] = previousAuxDataRepository
                    InjectedValues[\.userWalletRepository] = previousUserWalletRepository
                }

                let handler = CommonExpressRefundedTokenHandler(
                    converter: ExpressCurrencyConverter(supportedBlockchains: [ethereum.blockchain])
                )

                return try await handler.handle(
                    userWalletId: UserWalletId(value: Data([0x16, 0x81, 0x0])),
                    blockchainNetwork: ethereum,
                    expressCurrency: currency
                )
            }

            #expect(refundedToken == usdt)
        }
    }
}
