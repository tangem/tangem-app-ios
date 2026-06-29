//
//  AddressBookPersistentStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Local cache of the *encrypted* envelope (never the plaintext) for offline reads.
protocol AddressBookPersistentStorage {
    func loadEnvelope(for walletId: UserWalletId) -> AddressBookDTO.Envelope?
    func saveEnvelope(_ envelope: AddressBookDTO.Envelope, for walletId: UserWalletId) throws
    func clear(for walletId: UserWalletId)
}
