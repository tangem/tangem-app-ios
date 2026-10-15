//
//  PolymarketActivityDoubles.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket
@testable import Tangem

final class PolymarketLaunchDepositsReconcilerStub: PolymarketLaunchDepositsReconciling {
    private(set) var ownerAddresses: [String] = []

    func reconcileOncePerLaunch(ownerAddress: String) -> Task<Void, Never>? {
        ownerAddresses.append(ownerAddress)
        return nil
    }
}

final class PolymarketActivityServiceStub: PolymarketActivityService {
    var pages: [String?: Result<PolymarketActivityPage, Error>] = [:]
    private(set) var requestedCursors: [String?] = []
    private(set) var reconcileCount = 0

    func activity(filter: PolymarketActivityFilter, limit: Int, cursor: String?) async throws -> PolymarketActivityPage {
        requestedCursors.append(cursor)

        guard let result = pages[cursor] else {
            return PolymarketActivityPage(records: [], receivedCount: 0, nextCursor: nil)
        }

        return try result.get()
    }

    func reconcileDeposits() async -> PolymarketDepositsScan? {
        reconcileCount += 1
        return nil
    }
}
