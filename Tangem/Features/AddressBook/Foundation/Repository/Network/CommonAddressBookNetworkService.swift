//
//  CommonAddressBookNetworkService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Adapts the shared Tangem API service to the domain `AddressBookNetworkService`: a single-wallet load
/// is mapped onto the batch `sync` endpoint, a save onto the conditional `update`, and an
/// optimistic-locking conflict (412) is translated into `.inconsistentState`. The etag is opaque and
/// passed through verbatim — the client never generates or rewrites it.
final class CommonAddressBookNetworkService {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let mapper = AddressBookNetworkMapper()
}

extension CommonAddressBookNetworkService: AddressBookNetworkService {
    func loadAddressBook(walletId: UserWalletId, knownETag: String?) async throws -> AddressBookFetchResult {
        let request = AddressBookDTO.SyncRequest(
            wallets: [.init(walletId: walletId.stringValue, etag: knownETag)]
        )
        let response = try await tangemApiService.syncAddressBooks(request)

        guard let item = response.items.first(where: { $0.walletId == walletId.stringValue }) else {
            // The backend omits a wallet whose book matched the sent etag or doesn't exist yet. With a
            // known etag that is "not modified"; without one it means "no book for this wallet".
            return knownETag == nil ? .notFound : .notModified
        }

        return try .fetched(mapper.mapToEnvelope(item))
    }

    func saveAddressBook(_ envelope: AddressBookEnvelope, walletId: UserWalletId, knownETag: String?) async throws -> AddressBookSaveResult {
        do {
            let newETag = try await tangemApiService.updateAddressBook(
                walletId: walletId.stringValue,
                knownETag: knownETag,
                body: mapper.mapToUpdateRequest(envelope)
            )

            // `updatedAt` is authored by the client and echoed back unchanged, so the local envelope is
            // the source of truth for it; only the new etag has to come off the wire.
            return AddressBookSaveResult(etag: newETag, updatedAt: envelope.updatedAt)
        } catch let error as TangemAPIError where error.code == .optimisticLockingFailed {
            throw AddressBookNetworkServiceError.inconsistentState
        } catch {
            throw AddressBookNetworkServiceError.underlyingError(error)
        }
    }
}
