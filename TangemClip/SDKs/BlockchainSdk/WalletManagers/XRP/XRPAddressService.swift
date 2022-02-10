//
//  XRPAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public class XRPAddressService: AddressService {
    let curve: EllipticCurve
    
    init(curve: EllipticCurve) {
        self.curve = curve
    }
    
    public func makeAddress(from walletPublicKey: Data) -> String {
        var key: Data
        switch curve {
        case .secp256k1:
            key = try! Secp256k1Key(with: walletPublicKey).compress()
        case .ed25519, .secp256r1:
            key = [UInt8(0xED)] + walletPublicKey
        }
        let input = RIPEMD160.hash(message: key.sha256())
        let buffer = [0x00] + input
        let checkSum = Data(buffer.sha256().sha256()[0..<4])
        let walletAddress = String(base58: buffer + checkSum, alphabet: Base58String.xrpAlphabet)
        return walletAddress
    }
    
    public func validate(_ address: String) -> Bool {
        if XRPSeedWallet.validate(address: address) {
            return true
        }
        
        if let _ = try? XRPAddress.decodeXAddress(xAddress: address) {
            return true
        }
        
        return false
    }
}
