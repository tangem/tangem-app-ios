//
//  XRPAddressFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public class XRPAddressFactory {
    public func makeAddress(from walletPublicKey: Data) -> String {
        let input = RIPEMD160.hash(message: walletPublicKey.sha256())
        let buffer = [0x00] + input
        let checkSum = Data(buffer.sha256().sha256()[0..<4])
        let walletAddress = String(base58: buffer + checkSum, alphabet: Base58String.xrpAlphabet)
        return walletAddress
    }
}
