//
//  JointAccountDerivationUtils.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSdk
import CryptoSwift

enum JointAccountDerivationUtils {
    static func makeDerivedKey(seedKey: Data, derivationPath: DerivationPath, extendedPublicKey: ExtendedPublicKey) throws -> JointAccountDerivedKey {
        let publicKey = Wallet.PublicKey(
            seedKey: seedKey,
            derivationType: .plain(.init(path: derivationPath, extendedPublicKey: extendedPublicKey))
        )

        let addressService = AddressServiceFactory(blockchain: JointAccountKeyPath.blockchain).makeAddressService()
        let address = try addressService.makeAddress(for: publicKey, with: .default)

        return JointAccountDerivedKey(address: address.value, publicKey: publicKey)
    }

    /// The form the endpoint canonicalises what it receives into, and verifies the signature against — RFC 8785, whose
    /// property ordering and escaping this encoder already produces.
    /// - Warning: Pinned against the vector shared with the other platforms by `JointAccountSignedPayloadTests`; a
    /// change here that the test does not catch rejects every signature this app makes.
    static func canonicalPayload(of payload: some Encodable) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]

        return try encoder.encode(payload)
    }

    static func digest(payload: some Encodable) throws -> Data {
        let canonicalPayload = try canonicalPayload(of: payload)
        let prefix = "\u{19}Ethereum Signed Message:\n\(canonicalPayload.count)"

        return (Data(prefix.utf8) + canonicalPayload).sha3(.keccak256)
    }
}

/// - Note: The address is the one the other members know this member by.
struct JointAccountDerivedKey {
    let address: String
    let publicKey: Wallet.PublicKey
}
