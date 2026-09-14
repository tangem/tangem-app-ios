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
    private let userWalletId: UserWalletId
    private let ownerAddressProvider: PolymarketOwnerAddressProviding
    private let apiProvider: PolymarketAPIProvider

    init(
        userWalletId: UserWalletId,
        ownerAddressProvider: PolymarketOwnerAddressProviding,
        apiProvider: PolymarketAPIProvider
    ) {
        self.userWalletId = userWalletId
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

        let page = try await apiProvider.positions(
            request: PolymarketPositionsRequest(
                depositWalletAddress: depositWalletAddress,
                walletId: userWalletId.stringValue,
                limit: limit
            )
        )

        return page.positions
            .filter { $0.settlement == nil }
            .sorted(by: endsSooner)
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
