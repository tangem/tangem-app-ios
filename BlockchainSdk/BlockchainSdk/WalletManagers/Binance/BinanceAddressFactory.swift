//
//  BinanceAddressFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public class BinanceAddressFactory {
    public func makeAddress(from walletPublicKey: Data, testnet: Bool) -> String {
        let keyHash = RIPEMD160.hash(message: walletPublicKey.sha256())

        return testnet ? Bech32().encode("tbnb", values: keyHash) :
        Bech32().encode("bnb", values: keyHash)
    }
}
