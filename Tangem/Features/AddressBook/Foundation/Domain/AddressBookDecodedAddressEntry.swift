//
//  AddressBookDecodedAddressEntry.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// An address entry as it comes out of the decrypted blob, *before* its signature is verified.
/// This is the unit that is persisted and serialized. Call `AddressBookVerifiedAddressEntryBuilder.make(verifying:...)`
/// to obtain a verified entry that is safe to display and to pass into the Send Flow.
struct AddressBookDecodedAddressEntry: Hashable, Codable {
    let id: AddressBookAddressEntryID
    let address: String
    let networkId: AddressBookNetworkID
    let memo: String?
    /// Wallet-key signature over `AddressBookSignedTuplePayload.digest`. Its JSON encoding inside the blob is
    /// fixed by the blob codec (see the crypto layer) and is part of the cross-platform contract.
    let signature: Data
}
