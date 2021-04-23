//
//  StellarAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public class StellarAddressService: AddressService {
    public func makeAddress(from walletPublicKey: Data) -> String {
        guard let publicKey = try? StellarPublicKey(Array(walletPublicKey)) else {
            return ""
        }
        
        let keyPair = StellarKeyPair(publicKey: publicKey)
        return keyPair.accountId
    }
    
    public func validate(_ address: String) -> Bool {
        let keyPair = try? StellarKeyPair(accountId: address)
        return keyPair != nil
    }
}
