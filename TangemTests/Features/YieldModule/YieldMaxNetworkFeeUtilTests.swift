//
//  YieldMaxNetworkFeeUtilTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("YieldMaxNetworkFeeUtil")
struct YieldMaxNetworkFeeUtilTests {
    typealias SUT = YieldMaxNetworkFeeUtil

    @Test("Six decimal token lands on the token scale")
    func sixDecimalTokenUsesTokenScale() throws {
        let fee = try SUT().maxNetworkFee(
            maxFeeNative: Decimal(string: "0.0005")!,
            coinPrice: 3000,
            tokenPrice: 1,
            token: makeToken(decimalCount: 6)
        )

        #expect(fee == BigUInt(1_500_000))
    }

    @Test("Eighteen decimal token lands on the token scale")
    func eighteenDecimalTokenUsesTokenScale() throws {
        let fee = try SUT().maxNetworkFee(
            maxFeeNative: Decimal(string: "0.0005")!,
            coinPrice: 3000,
            tokenPrice: 1,
            token: makeToken(decimalCount: 18)
        )

        #expect(fee == BigUInt(stringLiteral: "1500000000000000000"))
    }

    @Test("Token price above one shrinks the cap")
    func tokenPriceAboveOneShrinksCap() throws {
        let fee = try SUT().maxNetworkFee(
            maxFeeNative: Decimal(string: "0.01")!,
            coinPrice: 4000,
            tokenPrice: Decimal(string: "2.5")!,
            token: makeToken(decimalCount: 6)
        )

        #expect(fee == BigUInt(16_000_000))
    }

    @Test("Missing token price throws instead of capping at zero")
    func missingTokenPriceThrows() {
        #expect(throws: YieldModuleError.self) {
            try SUT().maxNetworkFee(
                maxFeeNative: Decimal(string: "0.0005")!,
                coinPrice: 3000,
                tokenPrice: 0,
                token: makeToken(decimalCount: 6)
            )
        }
    }

    @Test("Missing coin price throws instead of capping at zero")
    func missingCoinPriceThrows() {
        #expect(throws: YieldModuleError.self) {
            try SUT().maxNetworkFee(
                maxFeeNative: Decimal(string: "0.0005")!,
                coinPrice: 0,
                tokenPrice: 1,
                token: makeToken(decimalCount: 6)
            )
        }
    }

    @Test("Missing max fee throws instead of capping at zero")
    func missingMaxFeeThrows() {
        #expect(throws: YieldModuleError.self) {
            try SUT().maxNetworkFee(
                maxFeeNative: 0,
                coinPrice: 3000,
                tokenPrice: 1,
                token: makeToken(decimalCount: 6)
            )
        }
    }

    private func makeToken(decimalCount: Int) -> Token {
        Token(
            name: "Tether",
            symbol: "USDT",
            contractAddress: "0xfde4c96c8593536e31f229ea8f37b2ada2699bb2",
            decimalCount: decimalCount,
            id: "tether"
        )
    }
}
