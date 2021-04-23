//
//  TezosAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Sodium

public class TezosAddressService: AddressService {
    public func makeAddress(from walletPublicKey: Data) -> String {
        let publicKeyHash = Sodium().genericHash.hash(message: walletPublicKey.bytes, outputLength: 20)!
        let tz1Prefix = Data(hex: "06A19F")
        let prefixedHash = tz1Prefix + publicKeyHash
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
