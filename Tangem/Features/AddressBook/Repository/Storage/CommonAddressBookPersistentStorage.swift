//
//  CommonAddressBookPersistentStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct CommonAddressBookPersistentStorage: AddressBookPersistentStorage {
    @Injected(\.persistentStorage) private var persistentStorage: PersistentStorageProtocol

    func loadEnvelope(for walletId: UserWalletId) -> AddressBookEnvelopeDTO? {
        try? persistentStorage.value(for: key(for: walletId))
    }

    func saveEnvelope(_ envelope: AddressBookEnvelopeDTO, for walletId: UserWalletId) throws {
        try persistentStorage.store(value: envelope, for: key(for: walletId))
    }

    func clear(for walletId: UserWalletId) {
        let empty: AddressBookEnvelopeDTO? = nil
        try? persistentStorage.store(value: empty, for: key(for: walletId))
    }

    private func key(for walletId: UserWalletId) -> PersistentStorageKey {
        .addressBook(cid: walletId.stringValue)
    }
}
