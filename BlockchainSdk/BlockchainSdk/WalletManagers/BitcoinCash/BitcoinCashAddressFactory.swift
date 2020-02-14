//
//  BitcoinCashAddressFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import BinanceChain

public class BitcoinCashAddressFactory {
    public func makeAddress(from walletPublicKey: Data) -> String {
        let prefix = Data([UInt8(0x00)]) //public key hash
        let payload = RIPEMD160.hash(message: walletPublicKey.sha256())
        let walletAddress = HDBech32.encode(prefix + payload, prefix: "bitcoincash")
        return walletAddress
    }
}
