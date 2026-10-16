//
//  PolymarketPositionsService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPolymarket

protocol PolymarketPositionsService {
    func activePositions(limit: Int) async throws -> PolymarketPositionsPage

    func openPositions(limit: Int, cursor: String?) async throws -> PolymarketPositionsPage

    func closedPositions(limit: Int, cursor: String?) async throws -> PolymarketClosedPositionsPage

    func position(conditionId: String, assetId: String) async throws -> PolymarketPosition?

    func awaitPosition(conditionId: String, assetId: String, changedFrom shares: Decimal?) async throws -> PolymarketPosition?
}

// MARK: - What still counts as an open position

extension PolymarketPosition {
    /// A position the user has sold out of keeps coming back from the list until the indexer drops it.
    var isEmptied: Bool {
        size <= 0
    }

    var isWorthShowing: Bool {
        !isEmptied && (settlement == nil || isRedeemable)
    }

    var opensClaim: Bool {
        (isRedeemable || settlement?.isResolved == true) && version?.isSupported == true
    }
}

struct CommonPolymarketPositionsService {
    private let ownerAddressProvider: PolymarketOwnerAddressProviding
    private let apiProvider: PolymarketAPIProvider

    init(
        ownerAddressProvider: PolymarketOwnerAddressProviding,
        apiProvider: PolymarketAPIProvider
    ) {
        self.ownerAddressProvider = ownerAddressProvider
        self.apiProvider = apiProvider
    }
}

// MARK: - PolymarketPositionsService protocol conformance

extension CommonPolymarketPositionsService: PolymarketPositionsService {
    func activePositions(limit: Int) async throws -> PolymarketPositionsPage {
        var collected: [PolymarketPosition] = []
        var seenIDs: Set<String> = []
        var received = 0
        var cursor: String?

        for _ in 0 ..< Constants.activePageScans {
            let page = try await openPositions(limit: limit, cursor: cursor)

            for position in page.positions where position.isWorthShowing && !seenIDs.contains(position.id) {
                seenIDs.insert(position.id)
                collected.append(position)
            }

            received += page.receivedCount
            cursor = page.nextCursor

            guard collected.count < limit, cursor != nil, page.receivedCount > 0 else { break }
        }

        return PolymarketPositionsPage(
            positions: collected.prefix(limit).sorted(by: endsSooner),
            receivedCount: received,
            nextCursor: cursor
        )
    }

    func openPositions(limit: Int, cursor: String?) async throws -> PolymarketPositionsPage {
        try await apiProvider.positions(
            request: PolymarketPositionsRequest(
                depositWalletAddress: ownerAddressProvider.depositWalletAddress(),
                page: .page(limit: limit, cursor: cursor)
            )
        )
    }

    func closedPositions(limit: Int, cursor: String?) async throws -> PolymarketClosedPositionsPage {
        try await apiProvider.closedPositions(
            request: PolymarketClosedPositionsRequest(
                depositWalletAddress: ownerAddressProvider.depositWalletAddress(),
                page: .page(limit: limit, cursor: cursor)
            )
        )
    }

    func position(conditionId: String, assetId: String) async throws -> PolymarketPosition? {
        try await apiProvider.positionOutcome(request: outcomeRequest(conditionId: conditionId, assetId: assetId))
    }

    func awaitPosition(conditionId: String, assetId: String, changedFrom shares: Decimal?) async throws -> PolymarketPosition? {
        let request = try outcomeRequest(conditionId: conditionId, assetId: assetId)

        var indexed: PolymarketPosition?

        for attempt in 0 ..< Constants.indexingAttempts {
            if attempt > 0 {
                try await Task.sleep(for: .seconds(Constants.indexingInterval))
            }

            guard let position = try await apiProvider.positionOutcome(request: request) else { continue }

            indexed = position

            if position.size != shares {
                return position
            }
        }

        return indexed
    }
}

// MARK: - Private implementation

private extension CommonPolymarketPositionsService {
    enum Constants {
        static let activePageScans = 3
        static let indexingAttempts = 6
        static let indexingInterval: TimeInterval = 1
    }

    func outcomeRequest(conditionId: String, assetId: String) throws -> PolymarketPositionOutcomeRequest {
        try PolymarketPositionOutcomeRequest(
            depositWalletAddress: ownerAddressProvider.depositWalletAddress(),
            conditionId: conditionId,
            assetId: assetId
        )
    }

    func endsSooner(_ lhs: PolymarketPosition, _ rhs: PolymarketPosition) -> Bool {
        switch (lhs.endDate, rhs.endDate) {
        case (.some(let lhs), .some(let rhs)): lhs < rhs
        case (.some, .none): true
        case (.none, .some), (.none, .none): false
        }
    }
}
