//
//  AddressBookETagStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

protocol AddressBookETagStorage {
    func loadETag(for userWalletId: UserWalletId) -> String?
    func saveETag(_ eTag: String, for userWalletId: UserWalletId)
    func clearETag(for userWalletId: UserWalletId)
}
