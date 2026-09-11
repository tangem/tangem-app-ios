//
//  RatingModelTransactionTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemExpress
@testable import Tangem

@Suite("RatingModel.Transaction")
struct RatingModelTransactionTests {
    typealias SUT = RatingModel.Transaction

    @Test("Only a settled swap is rateable", arguments: ExpressTransactionStatus.allCases)
    func rateableStatuses(status: ExpressTransactionStatus) {
        let rateable: Set<ExpressTransactionStatus> = [.finished, .refunded, .expired, .txFailed]

        #expect(SUT.isRateable(status) == rateable.contains(status))
    }
}
