//
//  CommonAddressBookNetworkService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// Stub implementation: there is no remote address book API yet.
/// - `getAddressBook` reports `notImplemented` so the manager keeps the local state untouched.
/// - `saveAddressBook` echoes the input back, so the remote-first write flow falls through to local persistence.
/// When the real API lands, replace the bodies with `TangemApiService` calls and `ETag` (`If-Match`) handling.
struct CommonAddressBookNetworkService {
    private let userWalletId: UserWalletId

    init(userWalletId: UserWalletId) {
        self.userWalletId = userWalletId
    }
}

// MARK: - AddressBookNetworkService protocol conformance

extension CommonAddressBookNetworkService: AddressBookNetworkService {
    func getAddressBook(retryCount: Int) async throws(AddressBookNetworkServiceError) -> RemoteAddressBookInfo {
        // [REDACTED_TODO_COMMENT]
        throw .notImplemented
    }

    func saveAddressBook(
        _ addressBook: AddressBook,
        version: String?,
        retryCount: Int
    ) async throws(AddressBookNetworkServiceError) -> RemoteAddressBookInfo {
        // [REDACTED_TODO_COMMENT]
        RemoteAddressBookInfo(addressBook: addressBook, version: version)
    }
}
