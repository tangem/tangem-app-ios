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
    func activePositions(limit: Int) async throws -> [PolymarketPosition]
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
    func activePositions(limit: Int) async throws -> [PolymarketPosition] {
        guard let ownerAddress = ownerAddressProvider.getOwnerAddress() else {
            throw PolymarketPositionsError.ownerAddressUnavailable
        }

        let depositWalletAddress = try PolymarketDepositWalletDeriver.derive(ownerAddress: ownerAddress)

        var collected: [PolymarketPosition] = []
        var offset = 0

        for _ in 0 ..< Constants.activePageScans {
            let page = try await apiProvider.positions(
                request: PolymarketPositionsRequest(
                    depositWalletAddress: depositWalletAddress,
                    limit: limit,
                    offset: offset
                )
            )

            collected += page.positions.filter { $0.settlement == nil }
            offset += page.positions.count

            guard collected.count < limit, page.hasNext, !page.positions.isEmpty else { break }
        }

        return Array(collected.sorted(by: endsSooner).prefix(limit))
    }
}

// MARK: - Private implementation

private extension CommonPolymarketPositionsService {
    func endsSooner(_ lhs: PolymarketPosition, _ rhs: PolymarketPosition) -> Bool {
        switch (lhs.endDate, rhs.endDate) {
        case (.some(let lhs), .some(let rhs)): lhs < rhs
        case (.some, .none): true
        case (.none, .some), (.none, .none): false
        }
    }
}

// MARK: - Constants

private extension CommonPolymarketPositionsService {
    enum Constants {
        static let activePageScans = 3
    }
}
