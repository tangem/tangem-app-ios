//
//  PolymarketPositionsLoader.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPolymarket

struct PolymarketPositionsLoader {
    let service: PolymarketPositionsService

    func load() async throws -> Snapshot {
        async let finished = probeFinishedPositions()
        let page = try await activePositions()

        return await Snapshot(activePage: page, hasFinishedPositions: finished)
    }
}

// MARK: - Snapshot

extension PolymarketPositionsLoader {
    struct Snapshot {
        let activePage: PolymarketPositionsPage
        let hasFinishedPositions: Bool?
    }
}

// MARK: - Private implementation

private extension PolymarketPositionsLoader {
    func activePositions() async throws -> PolymarketPositionsPage {
        do {
            return try await service.activePositions(limit: Constants.activeLimit)
        } catch {
            guard (error as? PolymarketAPIError)?.isTransient == true else { throw error }

            try await Task.sleep(for: .seconds(Constants.retryDelay))

            return try await service.activePositions(limit: Constants.activeLimit)
        }
    }

    func probeFinishedPositions() async -> Bool? {
        do {
            return try await closedPositionsExist()
        } catch {
            guard !error.isCancellationError else { return nil }

            PolymarketLogger.error("Failed to probe the closed positions", error: error)
            return nil
        }
    }

    func closedPositionsExist() async throws -> Bool {
        do {
            return try await closedPositionsPage().receivedCount > 0
        } catch {
            guard (error as? PolymarketAPIError)?.isTransient == true else { throw error }

            try await Task.sleep(for: .seconds(Constants.retryDelay))

            return try await closedPositionsPage().receivedCount > 0
        }
    }

    func closedPositionsPage() async throws -> PolymarketClosedPositionsPage {
        try await service.closedPositions(limit: Constants.finishedProbeLimit, cursor: nil)
    }
}

// MARK: - Constants

private extension PolymarketPositionsLoader {
    enum Constants {
        static let activeLimit = 10
        static let finishedProbeLimit = 1
        static let retryDelay: TimeInterval = 1
    }
}
