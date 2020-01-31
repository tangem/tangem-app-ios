//
//  AddressValidator.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public class BitcoinAddressValidator {
    var possibleFirstCharacters: [String] {
        ["1","2","3","n","m"]
    }
    
    func validate(_ address: String, testnet: Bool) -> Bool {
        guard !address.isEmpty else { return false }
        
        if possibleFirstCharacters.contains(String(address.first!)) {
            guard (26...35) ~= address.count else { return false }
            
        }
        else {
            let networkPrefix = testnet ? "tb" : "bc"
            guard let _ = try? SegWitBech32.decode(hrp: networkPrefix, addr: address) else { return false }
            
            return true
        }
        
        guard let decoded = Data(base58: address),
            decoded.count > 24 else {
                return false
        }
        
        let rip = decoded[0..<21]
        let kcv = rip.sha256().sha256()
        
        for i in 0..<4 {
            if kcv[i] != decoded[21+i] {
                return false
            }
        }
        
        if testnet && (address.starts(with: "1") || address.starts(with: "3")) {
            return false
        }
        
        return true
    }
}
