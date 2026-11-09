//
//  PendingExpressTransactionStatusTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import TangemExpress
@testable import Tangem

@Suite("PendingExpressTransactionStatus.isTerminated")
struct PendingExpressTransactionStatusTests {
    @Test("Swap: polling stops exactly on the terminal statuses")
    func swap() {
        let allStatuses: [PendingExpressTransactionStatus] = [
            .created, .awaitingDeposit, .awaitingHash, .confirming, .buying, .exchanging, .sendingToUser, .finished,
            .failed, .unknown, .refunded, .refunding, .verificationRequired, .expired, .paused, .txFailed,
        ]
        let terminated: Set<PendingExpressTransactionStatus> = [.finished, .refunded, .expired, .txFailed, .paused, .unknown]

        for status in allStatuses {
            #expect(status.isTerminated(branch: .swap) == terminated.contains(status), "\(status)")
        }
    }

    @Test("Onramp: polling stops exactly on the terminal statuses", arguments: OnrampTransactionStatus.allCases)
    func onramp(status: OnrampTransactionStatus) {
        let terminated: Set<OnrampTransactionStatus> = [.finished, .refunded, .expired, .failed, .paused, .unknown]

        let isTerminated = PendingOnrampTransactionFactory.pendingStatus(from: status).isTerminated(branch: .onramp)

        #expect(isTerminated == terminated.contains(status))
    }
}
