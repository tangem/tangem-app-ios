//
//  XRPAddressFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public class XRPAddressFactory {
    public func makeAddress(from walletPublicKey: Data, curve: EllipticCurve) -> String {
        var key: Data
        switch curve {
        case .secp256k1:
            key = Secp256k1Utils.convertKeyToCompressed(walletPublicKey)!
        case .ed25519:
            key = [UInt8(0xED)] + walletPublicKey
        }
        let input = RIPEMD160.hash(message: key.sha256())
        let buffer = [0x00] + input
        let checkSum = Data(buffer.sha256().sha256()[0..<4])
        let walletAddress = String(base58: buffer + checkSum, alphabet: Base58String.xrpAlphabet)
        return walletAddress
    }
}
