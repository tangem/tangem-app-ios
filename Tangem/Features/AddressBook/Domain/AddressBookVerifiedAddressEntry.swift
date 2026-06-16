//
//  AddressBookVerifiedAddressEntry.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// An address entry whose signature has been verified. There is no public initializer: the only way
/// to obtain a value is `make(verifying:...)`, so an unverified or forged entry cannot structurally
/// reach the UI or the Send Flow.
struct AddressBookVerifiedAddressEntry: Hashable {
    let id: AddressBookAddressEntryID
    let address: String
    let networkId: AddressBookNetworkID
    let memo: String?

    private init(id: AddressBookAddressEntryID, address: String, networkId: AddressBookNetworkID, memo: String?) {
        self.id = id
        self.address = address
        self.networkId = networkId
        self.memo = memo
    }

    /// Verifies `decoded` against the owning contact's `name`/`id` and the wallet public key. Returns
    /// `nil` when the signature does not match, so the caller drops the entry and reports analytics.
    static func make(
        verifying decoded: AddressBookDecodedAddressEntry,
        contactId: AddressBookContactID,
        contactName: AddressBookContactName,
        walletPublicKey: Data,
        verifier: AddressBookSignatureVerifying
    ) -> AddressBookVerifiedAddressEntry? {
        let payload = AddressBookSignedTuplePayload(
            address: decoded.address,
            networkId: decoded.networkId,
            memo: decoded.memo,
            contactId: contactId,
            name: contactName
        )

        guard verifier.isSignatureValid(decoded.signature, of: payload.digest, walletPublicKey: walletPublicKey) else {
            return nil
        }

        return AddressBookVerifiedAddressEntry(
            id: decoded.id,
            address: decoded.address,
            networkId: decoded.networkId,
            memo: decoded.memo
        )
    }
}
