//
//  TezosAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Sodium
import TangemSdk

public class TezosAddressService: AddressService {
    private let curve: EllipticCurve
    
    init(curve: EllipticCurve) {
        self.curve = curve
    }
    
    public func makeAddress(from walletPublicKey: Data) -> String {
        var key: Data
        switch curve {
        case .ed25519:
            key = walletPublicKey
        case .secp256k1:
            key = try! Secp256k1Key(with: walletPublicKey).compress()
        case .secp256r1:
            fatalError("Not implemented")
        }
        let publicKeyHash = Sodium().genericHash.hash(message: key.bytes, outputLength: 20)!
        let prefix = TezosPrefix.addressPrefix(for: curve)
        let prefixedHash = prefix + publicKeyHash
        let checksum = prefixedHash.sha256().sha256().prefix(4)
        let prefixedHashWithChecksum = prefixedHash + checksum
        return Base58.base58FromBytes(prefixedHashWithChecksum.bytes)
    }
    
    public func validate(_ address: String) -> Bool {
        guard let prefixedHashWithChecksum = address.base58DecodedData,
            prefixedHashWithChecksum.count == 27 else {
            return false
        }
        
        let prefixedHash = prefixedHashWithChecksum.prefix(23)
        let checksum = prefixedHashWithChecksum.suffix(from: 23)
        let calculatedChecksum = prefixedHash.sha256().sha256().prefix(4)
        return calculatedChecksum == checksum
    }
}
