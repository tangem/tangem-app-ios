//
//  AddressBookVerifiedAddressEntry.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

/// An address entry whose signature has been verified. Its initializer is `fileprivate`, so the only
/// way to obtain one is `AddressBookVerifiedAddressEntryBuilder` (declared alongside it): an unverified
/// or forged entry cannot structurally reach the UI or the Send Flow.
struct AddressBookVerifiedAddressEntry: AddressBookEntry {
    let id: AddressBookAddressEntryID
    let address: String
    let blockchain: BSDKBlockchain
    let memo: String?

    fileprivate init(id: AddressBookAddressEntryID, address: String, blockchain: BSDKBlockchain, memo: String?) {
        self.id = id
        self.address = address
        self.blockchain = blockchain
        self.memo = memo
    }
}

/// Verifies a decoded entry's signature against the owning contact's `name`/`id` and the wallet public
/// key, and only on success builds the `AddressBookVerifiedAddressEntry`. Returns `nil` when the
/// signature does not match, so the caller drops the entry (and reports analytics).
struct AddressBookVerifiedAddressEntryBuilder {
    let supportedBlockchains: Set<BSDKBlockchain>

    func make(
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

        // Exact networkId match keeps the derived networkId byte-identical to the signed key; an entry on a
        // chain the wallet no longer supports resolves to nil and is dropped like a signature failure.
        guard let blockchain = supportedBlockchains.first(where: { AddressBookNetworkID($0.networkId) == decoded.networkId }) else {
            return nil
        }

        return AddressBookVerifiedAddressEntry(
            id: decoded.id,
            address: decoded.address,
            blockchain: blockchain,
            memo: decoded.memo
        )
    }
}
