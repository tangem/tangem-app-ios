//
//  MainQRNoSupportedTokensContextTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem
@testable import BlockchainSdk

@Suite("MainQRNoSupportedTokensContext")
struct MainQRNoSupportedTokensContextTests {
    @Test("Trims and nil-ifies blank symbol and networkId")
    func trimsAndNilifies() {
        let context = MainQRNoSupportedTokensContext(symbol: "  ", networkId: " eth ", qrType: "type")

        #expect(context.symbol == nil)
        #expect(context.networkId == "eth")
        #expect(context.qrType == "type")
    }

    @Test("Keeps non-blank trimmed values")
    func keepsValues() {
        let context = MainQRNoSupportedTokensContext(symbol: " USDT ", networkId: nil)

        #expect(context.symbol == "USDT")
        #expect(context.networkId == nil)
        #expect(context.qrType == nil)
    }

    @Test("payment(_:) derives symbol, networkId and qrType from the request")
    func paymentFactory() {
        let request = MainQRPaymentRequest(
            blockchain: .ethereum(testnet: false),
            destinationAddress: "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            amount: nil,
            memo: nil,
            tokenSymbol: "USDT",
            tokenContractAddress: nil,
            rawTokenAmount: nil
        )

        let context = MainQRNoSupportedTokensContext.payment(request)

        #expect(context.symbol == "USDT")
        #expect(context.networkId == Blockchain.ethereum(testnet: false).networkId)
        #expect(context.qrType != nil)
    }
}
