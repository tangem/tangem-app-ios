//
//  SignedTuplePayload.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit

/// The single authority for the byte layout that is signed and verified for every `AddressEntry`.
///
/// Canonical bytes = UTF-8 of `address + networkId + (memo ?? "") + contactId + name`, concatenated
/// in exactly this order with no separators. A `nil` memo contributes an empty string. This layout
/// is a cross-platform contract: it must match other clients byte-for-byte, otherwise a signature
/// made on one device will not verify on another.
struct SignedTuplePayload {
    let address: String
    let networkId: AddressBookNetworkID
    let memo: String?
    let contactId: ContactID
    let name: ContactName

    var canonicalData: Data {
        var data = Data()
        data.append(Data(address.utf8))
        data.append(Data(networkId.rawValue.utf8))
        data.append(Data((memo ?? "").utf8))
        data.append(Data(contactId.stringValue.utf8))
        data.append(Data(name.value.utf8))
        return data
    }

    /// 32-byte SHA-256 digest passed directly to the signer and the verifier — neither re-hashes it.
    var digest: Data {
        Data(SHA256.hash(data: canonicalData))
    }
}
