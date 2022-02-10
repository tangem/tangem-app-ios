//
//  RskAddressService.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public class RskAddressService: AddressService {
    public func makeAddress(from walletPublicKey: Data) -> String {
        let walletPublicKey = try! Secp256k1Key(with: walletPublicKey).decompress()
        //skip secp256k1 prefix
        let keccak = walletPublicKey[1...].sha3(.keccak256)
        let addressBytes = keccak[12...]
        let hexAddressBytes = addressBytes.toHexString()
        let address = "0x" + hexAddressBytes
        return toChecksumAddress(address)!
    }
    
    public func validate(_ address: String) -> Bool {
        guard !address.isEmpty,
              address.lowercased().starts(with: "0x"),
              address.count == 42
        else {
            return false
        }
        
       
        if let checksummed = toChecksumAddress(address),
           checksummed == address {
            return true
        } else {
            let cleanHex = address.stripHexPrefix()
            if cleanHex.lowercased() != cleanHex && cleanHex.uppercased() != cleanHex {
                return false
            }
        }
        
        return true
    }
    
    public func toChecksumAddress(_ address: String) -> String? {
        let lowercasedAddress = address.lowercased()
        let addressToHash = "30\(lowercasedAddress)"
        guard let hash = addressToHash.data(using: .utf8)?.sha3(.keccak256).toHexString() else {
            return nil
        }
        
        var ret = "0x"
        let hashChars = Array(hash)
        let addressChars = Array(lowercasedAddress.remove("0x"))
        for i in 0..<addressChars.count {
            guard let intValue = Int(String(hashChars[i]), radix: 16) else {
                return nil
            }
            
            if intValue >= 8 {
                ret.append(addressChars[i].uppercased())
            } else {
                ret.append(addressChars[i])
            }
        }
        return ret
    }
    
}
