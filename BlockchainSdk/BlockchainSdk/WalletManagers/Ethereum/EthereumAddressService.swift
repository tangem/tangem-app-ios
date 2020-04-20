//
//  EthereumAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public class EthereumAddressService: AddressService {
    public func makeAddress(from walletPublicKey: Data) -> String {
        //skip secp256k1 prefix
        let keccak = walletPublicKey[1...].sha3(.keccak256)
        let addressBytes = keccak[12...]
        let hexAddressBytes = addressBytes.toHexString()
        return "0x" + hexAddressBytes
    }
    
    public func validate(_ address: String) -> Bool {
        guard !address.isEmpty,
            address.lowercased().starts(with: "0x"),
            address.count == 42
            else {
                return false
        }
        
        return true
    }
}
