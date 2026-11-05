//
//  SentExpressTransactionHistoryMapperTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem
@testable import TangemExpress
@testable import BlockchainSdk

@Suite("SentExpressTransactionHistoryMapper")
struct SentExpressTransactionHistoryMapperTests {
    @Test("A just-sent swap keeps the rate type of the provider it was sent with", arguments: [ExpressProviderRateType.float, .fixed])
    func keepsTheRateType(rateType: ExpressProviderRateType) {
        let transaction = SentExpressTransactionHistoryMapper.mapToExchangeTransaction(makeSentTransaction(rateType: rateType))

        #expect(transaction.rateType == rateType)
    }

    private func makeSentTransaction(rateType: ExpressProviderRateType) -> SentSwapTransactionData {
        let blockchain = Blockchain.ethereum(testnet: false)
        let tokenItem = TokenItem.blockchain(.init(blockchain, derivationPath: nil))

        return SentSwapTransactionData(
            expressUserWalletId: "wallet",
            result: TransactionDispatcherResult(hash: "hash", url: nil, signerType: "stub", currentHost: "host"),
            source: SendSourceTokenStub(tokenItem: tokenItem),
            receive: CommonSendReceiveTokenFactory(tokenItem: tokenItem).makeSendReceiveToken(),
            fee: Fee(Amount(with: blockchain, type: .coin, value: 1)),
            provider: ExpressProvider(
                id: "provider",
                name: "Provider",
                type: .cex,
                exchangeOnlyWithinSingleAddress: false,
                imageURL: nil,
                termsOfUse: nil,
                privacyPolicy: nil,
                recommended: nil,
                slippage: nil,
                isCustomSlippageSupported: false
            ),
            rateType: rateType,
            date: Date(timeIntervalSince1970: 1_700_000_000),
            expressTransactionData: ExpressTransactionDataFixture.make()
        )
    }
}
