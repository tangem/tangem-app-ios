//
//  OnrampStatusScreenStateTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization
import TangemUI
import Testing
@testable import Tangem

@Suite("Onramp status screen state")
struct OnrampStatusScreenStateTests {
    typealias SUT = OnrampStatusScreenViewModel.State

    @Test("Before the first status arrives the screen waits for the deposit")
    func noStatusAwaitsDeposit() {
        #expect(SUT.make(status: nil) == SUT(
            title: Localization.expressExchangeStatusReceivingActive,
            glyph: .pending,
            appearance: .info
        ))
    }

    @Test(
        "An unfinished purchase shows its current step with the pending spinner",
        arguments: [
            PendingExpressTransactionStatus.created,
            .awaitingDeposit,
            .confirming,
            .buying,
            .exchanging,
            .sendingToUser,
            .refunding,
        ]
    )
    func inProgressShowsCurrentStep(status: PendingExpressTransactionStatus) {
        #expect(SUT.make(status: status) == SUT(title: status.activeStatusTitle, glyph: .pending, appearance: .info))
    }

    @Test("A finished purchase is shown as completed")
    func finishedIsSuccess() {
        #expect(SUT.make(status: .finished) == SUT(
            title: Localization.expressExchangeStatusBought,
            glyph: .checkmark,
            appearance: .success
        ))
    }

    @Test(
        "A purchase that needs the user's action is a warning",
        arguments: [PendingExpressTransactionStatus.awaitingHash, .verificationRequired]
    )
    func actionRequiredIsWarning(status: PendingExpressTransactionStatus) {
        #expect(SUT.make(status: status) == SUT(title: status.activeStatusTitle, glyph: .warning, appearance: .warning))
    }

    @Test(
        "A failed, canceled, paused or refunded purchase is an error",
        arguments: [PendingExpressTransactionStatus.failed, .unknown, .txFailed, .expired, .paused, .refunded]
    )
    func failureIsError(status: PendingExpressTransactionStatus) {
        #expect(SUT.make(status: status) == SUT(title: status.activeStatusTitle, glyph: .heartBroken, appearance: .error))
    }
}
