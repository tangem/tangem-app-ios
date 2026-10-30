//
//  StakingChipSubtitleTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Staking chip subtitle")
struct StakingChipSubtitleTests {
    private let stakingContract = TransactionViewModel.SubtitleOwner.unresolved(
        short: "0x0000...2002",
        fullAddress: "0x0000000000000000000000000000000000002002",
        blockiesImage: nil
    )

    @Test(
        "Staking chips drop the staking contract they were sent to",
        arguments: [
            TransactionViewModel.TransactionType.stake,
            .unstake,
            .vote,
            .restake,
            .withdraw,
        ]
    )
    func stakingChipHasNoSubtitle(transactionType: TransactionViewModel.TransactionType) {
        #expect(display(transactionType: transactionType, isOutgoing: true).subtitle == nil)
        #expect(display(transactionType: transactionType, isOutgoing: false).subtitle == nil)
    }

    @Test("An approve chip keeps its spender")
    func approveChipKeepsSpender() {
        #expect(display(transactionType: .approve, isOutgoing: true).subtitle == .owner(direction: .outgoing, owner: stakingContract))
    }

    private func display(
        transactionType: TransactionViewModel.TransactionType,
        isOutgoing: Bool
    ) -> TransactionDisplayModel {
        TransactionDisplayModel.make(
            transactionType: transactionType,
            status: .confirmed,
            isOutgoing: isOutgoing,
            isFromYieldContract: false,
            legacyName: "",
            addressDestination: "Contract: 0x0000...2002",
            subtitleOwner: stakingContract,
            isTangemPayCounterparty: false,
            expressSubtitle: nil
        )
    }
}
