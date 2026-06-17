//
//  AddressBookNetworkService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Transport for the encrypted address-book blob. The backend stores the blob opaquely; all CRUD is
/// performed on the client. `knownETag` drives conditional fetch (load) and optimistic locking (save).
protocol AddressBookNetworkService {
    func loadAddressBook(walletId: UserWalletId, knownETag: String?) async throws -> AddressBookFetchResult
    func saveAddressBook(_ envelope: AddressBookEnvelope, walletId: UserWalletId, knownETag: String?) async throws -> AddressBookSaveResult
}
