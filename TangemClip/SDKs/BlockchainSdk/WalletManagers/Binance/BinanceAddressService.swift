//
//  BinanceAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public class BinanceAddressService: AddressService {
    let testnet: Bool
    
    init(testnet: Bool) {
        self.testnet = testnet
    }
    
    public func makeAddress(from walletPublicKey: Data) -> String {
        let compressedKey = try! Secp256k1Key(with: walletPublicKey).compress()
        let keyHash = RIPEMD160.hash(message: compressedKey.sha256())
        
        return testnet ? Bech32().encode("tbnb", values: keyHash) :
            Bech32().encode("bnb", values: keyHash)
    }
    
    public func validate(_ address: String) -> Bool {
        if address.isEmpty {
            return false
        }
        
        guard let _ = try? Bech32().decode(address) else {
            return false
        }
        
        if !testnet && !address.starts(with: "bnb1") {
            return false
        }
        
        if testnet && !address.starts(with: "tbnb1") {
            return false
        }
        
        return true
    }
}
