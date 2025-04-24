//
//  SignatureInfo.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct SignatureInfo: CustomStringConvertible {
    public let signature: Data
    public let publicKey: Data
    /// The data which was signed
    public let hash: Data

    public var description: String {
        ["signature": signature.hex(), "publicKey": publicKey.hex(), "hash": hash.hex()].description
    }

    public init(signature: Data, publicKey: Data, hash: Data) {
        self.signature = signature
        self.publicKey = publicKey
        self.hash = hash
    }
}

public extension SignatureInfo {
    func unmarshal() throws -> Data {
        try Secp256k1Signature(with: signature).unmarshal(with: publicKey, hash: hash).data
    }

    func der() throws -> Data {
        try Secp256k1Utils().serializeDer(signature)
    }
}
