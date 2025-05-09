//
//  VisaAcceptanceSignatureProcessor.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct VisaAcceptanceSignatureProcessor {
    public init() {}

    public func processAcceptanceSignature(signature: Data, walletPublicKey: Data, originHash: Data) throws -> Data {
        let secpSignature = try Secp256k1Signature(with: signature)
        return try secpSignature.unmarshal(with: walletPublicKey, hash: originHash).data
    }
}
