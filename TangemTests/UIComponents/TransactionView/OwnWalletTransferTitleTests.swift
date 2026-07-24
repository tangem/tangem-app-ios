//
//  OwnWalletTransferTitleTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemLocalization
@testable import Tangem

@Suite("Own-wallet transfer title ([REDACTED_INFO])")
struct OwnWalletTransferTitleTests {
    @Test("Transfer to an own wallet is titled Transferred regardless of direction")
    func ownWalletTransferIsTransferred() {
        #expect(title(owner: .wallet(name: "My Wallet"), isOutgoing: true, status: .confirmed) == Localization.commonTransferred)
        #expect(title(owner: .wallet(name: "My Wallet"), isOutgoing: false, status: .confirmed) == Localization.commonTransferred)
    }

    @Test("Own-wallet transfer follows status for in-progress and failed")
    func ownWalletTransferStatuses() {
        #expect(title(owner: .wallet(name: "My Wallet"), isOutgoing: true, status: .inProgress) == Localization.commonTransfer)
        #expect(
            title(owner: .wallet(name: "My Wallet"), isOutgoing: true, status: .failed)
                == Localization.commonActionFailed(Localization.commonTransfer)
        )
    }

    @Test("Transfer to an external address stays Send/Received")
    func externalTransferStaysDirectional() {
        let external = TransactionViewModel.SubtitleOwner.unresolved(short: "0xAB…CD", fullAddress: "0xABCD", blockiesImage: nil)
        #expect(title(owner: external, isOutgoing: true, status: .confirmed) == Localization.commonSent)
        #expect(title(owner: external, isOutgoing: false, status: .confirmed) == Localization.commonReceived)
        #expect(title(owner: nil, isOutgoing: true, status: .confirmed) == Localization.commonSent)
        #expect(title(owner: nil, isOutgoing: false, status: .confirmed) == Localization.commonReceived)
    }

    private func title(
        owner: TransactionViewModel.SubtitleOwner?,
        isOutgoing: Bool,
        status: TransactionViewModel.Status
    ) -> String {
        TransactionDisplayModel.make(
            transactionType: .transfer,
            status: status,
            isOutgoing: isOutgoing,
            isFromYieldContract: false,
            legacyName: "Transfer",
            amount: "1",
            addressDestination: nil,
            subtitleOwner: owner
        ).title
    }
}
