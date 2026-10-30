//
//  SendingFeeSubtitleTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
import TangemLocalization
@testable import Tangem

@Suite("Sending fee subtitle")
struct SendingFeeSubtitleTests {
    @Test("A fee paid for a Yield mode operation names the operation, not the token")
    func feeForYieldOperationNamesTheOperation() {
        let token = Token(name: "Tether", symbol: "USDT", contractAddress: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t", decimalCount: 6)
        let tokenItem = TokenItem.token(token, .init(.tron(testnet: false), derivationPath: nil))
        let sent = TransactionViewModel.SentTokens(
            amount: "1.00 USDT",
            symbol: "USDT",
            iconInfo: TokenIconInfoBuilder().build(from: tokenItem, isCustom: false)
        )

        let display = TransactionDisplayModel.make(
            transactionType: .networkFee(purpose: .yieldMode(.activation), sent: sent),
            status: .confirmed,
            isOutgoing: true,
            isFromYieldContract: false,
            legacyName: "",
            addressDestination: nil,
            subtitleOwner: nil,
            isTangemPayCounterparty: false,
            expressSubtitle: nil
        )

        #expect(display.subtitle == .text(Localization.transactionHistoryFeeForYieldModeActivation))
    }
}
