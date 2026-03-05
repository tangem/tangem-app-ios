//
//  CommonWalletsNetworkService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils
import TangemFoundation

/// Common implementation of `WalletsNetworkService` protocol.
final class CommonWalletsNetworkService {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let userWalletId: UserWalletId

    init(userWalletId: UserWalletId) {
        self.userWalletId = userWalletId
    }
}

// MARK: - WalletsNetworkService protocol conformance

extension CommonWalletsNetworkService: WalletsNetworkService {
    func createWallet(with context: some Encodable) async throws -> String? {
        try await tangemApiService.createWallet(with: context)
    }

    func updateWallet(context: some Encodable) async throws {
        try await tangemApiService.updateWallet(by: userWalletId.stringValue, context: context)
    }
}
