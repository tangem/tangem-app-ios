//
//  CommonExpressExchangeDataDecoder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping
import TangemSdk

struct CommonExpressExchangeDataDecoder: ExpressExchangeDataDecoder {
    let publicKey: String

    func decode(txDetailsJson: String, signature: String) throws -> DecodedTransactionDetails {
        let data = Data(txDetailsJson.utf8)
        let signature = try Secp256k1Signature(with: Data(signature.utf8))
        print("->> signature", signature)
        let keySDK = "LS0tLS1CRUdJTiBQVUJMSUMgS0VZLS0tLS0KTUZZd0VBWUhLb1pJemowQ0FRWUZLNEVFQUFvRFFnQUU1SEVvbTlyT1lDUmpVeCtGTzJRMmJ3ZHdYYW5lSlYxegpsQVlSb1d2QS9zWSswVldoOUNiUjdaUFNYSWVXOEhlbEZtNlIwa3d3WkxQcVAvWktpbXNQWVE9PQotLS0tLUVORCBQVUJMSUMgS0VZLS0tLS0K"
//        let key = try Secp256k1Key(with: Data(publicKey.utf8))
//        print("->> key", key)
        let hexString = "4d465977454159484b6f5a497a6a3043415159464b34454541416f44516741453236663567497334642b74707476337a33626177346555347445352f66776b6c71336133516455306d784d3477522f7843552f7733686d44414967345368455a5255652b53426d575942473976727574327661544d413d3d"

        guard try signature.verify(with: Data(publicKey.utf8), message: data) else {
            throw ExpressExchangeDataDecoderError.invalidSignature
        }
//        print("->> signature verify", key)

        let details = try JSONDecoder().decode(DecodedTransactionDetails.self, from: data)
        return details
    }
}

enum ExpressExchangeDataDecoderError: Error {
    case invalidSignature
}
