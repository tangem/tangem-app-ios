//
//  PendingSignatureTitleTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import TangemLocalization
@testable import Tangem

@Suite("Title of a joint account operation in the token history")
struct PendingSignatureTitleTests {
    @Test("An operation still collecting signatures is titled Send; one already sent to the network is titled Sending")
    func titleFollowsThePendingSignature() {
        #expect(title(isPendingSignature: true) == Localization.commonSend)
        #expect(title(isPendingSignature: false) == Localization.commonSending)
    }

    @Test("A transaction other than a transfer keeps its own title while signatures are collected")
    func pendingSignatureTitlesOnlyTransfers() {
        #expect(title(transactionType: .approve, isPendingSignature: true) == title(transactionType: .approve, isPendingSignature: false))
    }

    private func title(transactionType: TransactionViewModel.TransactionType = .transfer, isPendingSignature: Bool) -> String {
        TransactionDisplayModel.make(
            transactionType: transactionType,
            status: .inProgress,
            isOutgoing: true,
            isFromYieldContract: false,
            legacyName: "Transfer",
            addressDestination: nil,
            subtitleOwner: nil,
            isTangemPayCounterparty: false,
            expressSubtitle: nil,
            isPendingSignature: isPendingSignature
        ).title.fullText
    }
}
