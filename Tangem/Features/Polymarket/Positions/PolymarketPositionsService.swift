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

    func openPositions(
        sort: PolymarketPositionsRequest.Sort,
        ascending: Bool,
        limit: Int,
        offset: Int
    ) async throws -> PolymarketPositionsPage

    func closedPositions(
        sort: PolymarketClosedPositionsRequest.Sort,
        ascending: Bool,
        limit: Int,
        offset: Int
    ) async throws -> PolymarketClosedPositionsPage

    func position(conditionId: String, assetId: String) async throws -> PolymarketPosition?

    func awaitPosition(conditionId: String, assetId: String, changedFrom shares: Decimal?) async throws -> PolymarketPosition?
}

enum PolymarketPositionsError: Error {
    case ownerAddressUnavailable
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
        var received = 0
        var offset = 0
        var hasNext = false

        for _ in 0 ..< Constants.activePageScans {
            let page = try await openPositions(sort: .endDate, ascending: true, limit: limit, offset: offset)

            collected += page.positions.filter { $0.settlement == nil }
            received += page.receivedCount
            offset += page.receivedCount
            hasNext = page.hasNext || page.receivedCount == limit

            guard collected.count < limit, hasNext, page.receivedCount > 0 else { break }
        }

        return PolymarketPositionsPage(
            positions: Array(collected.sorted(by: endsSooner).prefix(limit)),
            receivedCount: received,
            hasNext: hasNext
        )
    }

    func openPositions(
        sort: PolymarketPositionsRequest.Sort,
        ascending: Bool,
        limit: Int,
        offset: Int
    ) async throws -> PolymarketPositionsPage {
        try await apiProvider.positions(
            request: PolymarketPositionsRequest(
                depositWalletAddress: depositWalletAddress(),
                sort: sort,
                ascending: ascending,
                limit: limit,
                offset: offset
            )
        )
    }

    func closedPositions(
        sort: PolymarketClosedPositionsRequest.Sort,
        ascending: Bool,
        limit: Int,
        offset: Int
    ) async throws -> PolymarketClosedPositionsPage {
        try await apiProvider.closedPositions(
            request: PolymarketClosedPositionsRequest(
                depositWalletAddress: depositWalletAddress(),
                sort: sort,
                ascending: ascending,
                limit: limit,
                offset: offset
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
            depositWalletAddress: depositWalletAddress(),
            conditionId: conditionId,
            assetId: assetId
        )
    }

    func depositWalletAddress() throws -> String {
        guard let ownerAddress = ownerAddressProvider.getOwnerAddress() else {
            throw PolymarketPositionsError.ownerAddressUnavailable
        }

        return try PolymarketDepositWalletDeriver.derive(ownerAddress: ownerAddress)
    }

    func endsSooner(_ lhs: PolymarketPosition, _ rhs: PolymarketPosition) -> Bool {
        switch (lhs.endDate, rhs.endDate) {
        case (.some(let lhs), .some(let rhs)): lhs < rhs
        case (.some, .none): true
        case (.none, .some), (.none, .none): false
        }
    }
}
