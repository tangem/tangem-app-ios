//
//  BitcoinAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public class BitcoinAddressService: AddressService {
    let testnet: Bool
    var possibleFirstCharacters: [String] { ["1","2","3","n","m"] }
    
    init(testnet: Bool) {
        self.testnet = testnet
    }
    
    public func makeAddress(from walletPublicKey: Data) -> String {
        let hash = walletPublicKey.sha256()
        let ripemd160Hash = RIPEMD160.hash(message: hash)
        let netSelectionByte = getNetwork(testnet)
        let entendedRipemd160Hash = netSelectionByte + ripemd160Hash
        let sha = entendedRipemd160Hash.sha256().sha256()
        let ripemd160HashWithChecksum = entendedRipemd160Hash + sha[..<4]
        let base58 = String(base58: ripemd160HashWithChecksum)
        return base58
    }
    
    public func validate(_ address: String) -> Bool {
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
    
    func getNetwork(_ testnet: Bool) -> Data {
        return testnet ? Data([UInt8(0x6F)]): Data([UInt8(0x00)])
    }
}
