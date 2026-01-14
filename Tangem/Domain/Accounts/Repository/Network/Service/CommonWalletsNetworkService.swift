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
    @Injected(\.cryptoAccountsETagStorage) private var eTagStorage: CryptoAccountsETagStorage

    private let userWalletId: UserWalletId

    init(userWalletId: UserWalletId) {
        self.userWalletId = userWalletId
    }
}

// MARK: - WalletsNetworkService protocol conformance

extension CommonWalletsNetworkService: WalletsNetworkService {
    func createWallet(with context: some Encodable) async throws(CryptoAccountsNetworkServiceError) {
        do {
            let newRevision = try await tangemApiService.createWallet(with: context)

            if let newRevision {
                eTagStorage.saveETag(newRevision, for: userWalletId)
            }
        } catch let error as CryptoAccountsNetworkServiceError {
            throw error // Just re-throw an original error
        } catch {
            throw .underlyingError(error)
        }
    }

    func updateWallet(userWalletId: String, context: some Encodable) async throws(CryptoAccountsNetworkServiceError) {
        do {
            try await tangemApiService.updateWallet(by: userWalletId, context: context)
        } catch let error as CryptoAccountsNetworkServiceError {
            throw error // Just re-throw an original error
        } catch {
            throw .underlyingError(error)
        }
    }
}
