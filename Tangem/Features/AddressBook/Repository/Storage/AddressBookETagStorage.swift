//
//  AddressBookETagStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol AddressBookETagStorage: Initializable {
    func loadETag(for userWalletId: UserWalletId) -> String?
    func saveETag(_ eTag: String, for userWalletId: UserWalletId)
    func clearETag(for userWalletId: UserWalletId)
}
