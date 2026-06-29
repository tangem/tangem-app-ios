//
//  AddressBookEnvelope.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// The open header plus the encrypted payload of an address book, as stored on the backend.
/// `version` and `updatedAt` are readable without decryption; `updatedAt` is authored by the client
/// and echoed back by the backend unchanged.
struct AddressBookEnvelope: Hashable {
    let version: String
    let walletId: UserWalletId
    let updatedAt: Date
    let sealedBox: AddressBookSealedBox
}
