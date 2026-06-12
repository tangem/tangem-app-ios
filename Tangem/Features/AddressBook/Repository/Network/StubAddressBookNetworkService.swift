//
//  StubAddressBookNetworkService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import TangemFoundation

/// In-memory network stub used until the real backend integration (T4). It stores envelopes per
/// wallet and honours etag-based conditional fetch, so the repository's load/save paths can be
/// exercised end to end without a backend.
final class StubAddressBookNetworkService {
    private let storage = OSAllocatedUnfairLock(initialState: [String: RemoteAddressBook]())

    private func makeETag(for sealedBox: AddressBookSealedBox) -> String {
        Data(SHA256.hash(data: sealedBox.ciphertext)).map { String(format: "%02x", $0) }.joined()
    }
}

extension StubAddressBookNetworkService: AddressBookNetworkService {
    func loadAddressBook(walletId: UserWalletId, knownETag: String?) async throws -> AddressBookFetchResult {
        storage.withLock { books in
            guard let remote = books[walletId.stringValue] else {
                return .notFound
            }

            if let knownETag, knownETag == remote.etag {
                return .notModified
            }

            return .fetched(remote)
        }
    }

    func saveAddressBook(_ envelope: AddressBookEnvelope, walletId: UserWalletId, knownETag: String?) async throws -> AddressBookSaveResult {
        let etag = makeETag(for: envelope.sealedBox)
        let remote = RemoteAddressBook(etag: etag, envelope: envelope)

        storage.withLock { books in
            books[walletId.stringValue] = remote
        }

        return AddressBookSaveResult(etag: etag, updatedAt: envelope.updatedAt)
    }
}
