//
//  AddressFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public class BitcoinAddressFactory {
    public func makeAddress(from walletPublicKey: Data, testnet: Bool) -> String {
        let hash = walletPublicKey.sha256()
        let ripemd160Hash = RIPEMD160.hash(message: hash)
        let netSelectionByte = getNetwork(testnet)
        let entendedRipemd160Hash = netSelectionByte + ripemd160Hash
        let sha = entendedRipemd160Hash.sha256().sha256()
        let ripemd160HashWithChecksum = entendedRipemd160Hash + sha[..<4]
        let base58 = String(base58: ripemd160HashWithChecksum)
        return base58
    }
    
    func getNetwork(_ testnet: Bool) -> Data {
        return testnet ? Data(hex:"6F") : Data(hex:"00")
    }
}
