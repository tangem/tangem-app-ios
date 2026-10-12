//
//  TransactionDetailsAmountTextBuilderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

@Suite("TransactionDetailsAmountTextBuilder")
struct TransactionDetailsAmountTextBuilderTests {
    @Test("Holds the ticker to the number with a non-breaking space")
    func tickerFollowsNumber() {
        #expect(TransactionDetailsAmountTextBuilder.build("0.10", symbol: "USDC") == "0.10\u{a0}USDC")
    }

    @Test("Holds the sign to the number with a non-breaking space", arguments: ["−", "+", "~"])
    func signIsSpaced(sign: String) {
        #expect(TransactionDetailsAmountTextBuilder.build("0.10", symbol: "USDC", sign: sign) == "\(sign)\u{a0}0.10\u{a0}USDC")
    }

    @Test("Trims every part, so a sign that already carries a space is not spaced twice")
    func partsAreTrimmed() {
        #expect(TransactionDetailsAmountTextBuilder.build(" 0.10 ", symbol: " USDC ", sign: "~ ") == "~\u{a0}0.10\u{a0}USDC")
    }

    @Test("Leaves out an empty sign or ticker without a dangling space", arguments: [nil, "", " "])
    func emptyPartsAreDropped(part: String?) {
        #expect(TransactionDetailsAmountTextBuilder.build("0.10", symbol: part, sign: part) == "0.10")
        #expect(TransactionDetailsAmountTextBuilder.build("0.10", symbol: "USDC", sign: part) == "0.10\u{a0}USDC")
        #expect(TransactionDetailsAmountTextBuilder.build("0.10", symbol: part, sign: "−") == "−\u{a0}0.10")
    }

    @Test("Builds nothing without a number", arguments: [nil, "", " "])
    func emptyAmountBuildsNothing(amount: String?) {
        #expect(TransactionDetailsAmountTextBuilder.build(amount, symbol: "USDC", sign: "−") == nil)
    }
}
