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
    var holdsFirstPage = false
    private(set) var requestedCursors: [String?] = []
    private(set) var reconcileCount = 0
    private var heldFirstPage: CheckedContinuation<Void, Never>?

    var isHoldingFirstPage: Bool {
        heldFirstPage != nil
    }

    func releaseFirstPage() {
        holdsFirstPage = false
        heldFirstPage?.resume()
        heldFirstPage = nil
    }

    func activity(filter: PolymarketActivityFilter, limit: Int, cursor: String?) async throws -> PolymarketActivityPage {
        requestedCursors.append(cursor)

        if cursor == nil, holdsFirstPage {
            await withCheckedContinuation { heldFirstPage = $0 }
        }

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

final class PolymarketActivityRoutableSpy: PolymarketActivityRoutable, PolymarketActivityDetailsRoutable {
    private(set) var openedRecords: [PolymarketActivityRecord] = []
    private(set) var closeCount = 0

    func closeActivity() {
        closeCount += 1
    }

    func shareActivityExport(url: URL) {}

    func openActivityDetails(record: PolymarketActivityRecord) {
        openedRecords.append(record)
    }

    func closeActivityDetails() {}

    func openActivityEvent(eventID: String) {}
}
