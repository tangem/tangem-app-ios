//
//  SignatureInfo.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct SignatureInfo: CustomStringConvertible {
    let signature: Data
    let publicKey: Data
    /// The data which was signed
    let hash: Data

    var description: String {
        "signature: \(signature.hex())\npublicKey: \(publicKey.hex())\nhash: \(hash)"
    }
}

extension SignatureInfo {
    func unmarshal() throws -> Data {
        try Secp256k1Signature(with: signature).unmarshal(with: publicKey, hash: hash).data
    }
}
