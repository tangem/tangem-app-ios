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
    func loadEnvelope(for walletId: UserWalletId) -> AddressBookEnvelopeDTO?
    func saveEnvelope(_ envelope: AddressBookEnvelopeDTO, for walletId: UserWalletId) throws
    func clear(for walletId: UserWalletId)
}
