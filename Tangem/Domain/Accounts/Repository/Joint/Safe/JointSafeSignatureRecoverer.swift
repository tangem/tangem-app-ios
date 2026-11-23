//
//  JointSafeSignatureRecoverer.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSdk

enum JointSafeSignatureRecoverer {
    static func recoverSigner(ofDigest digest: Data, signature: String) throws -> String {
        let publicKey = try Secp256k1Key(with: extendedSignature(from: signature), hash: digest).decompress()
        let addressService = AddressServiceFactory(blockchain: JointAccountKeyPath.blockchain).makeAddressService()
        let address = try addressService.makeAddress(
            for: Wallet.PublicKey(seedKey: publicKey, derivationType: nil),
            with: .default
        )

        return address.value
    }

    private static func extendedSignature(from signature: String) throws(SignatureError) -> Secp256k1Signature.Extended {
        let data = Data(hexString: signature)

        guard data.count == 65, data[64] == 27 || data[64] == 28 else {
            throw .malformedSignature
        }

        return Secp256k1Signature.Extended(
            r: Data(data[0 ..< 32]),
            s: Data(data[32 ..< 64]),
            v: Data(data[64 ..< 65])
        )
    }
}

// MARK: - Auxiliary types

extension JointSafeSignatureRecoverer {
    enum SignatureError: Error {
        case malformedSignature
    }
}
