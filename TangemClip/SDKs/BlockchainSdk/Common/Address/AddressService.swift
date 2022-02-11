//
//  AddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public protocol AddressService: MultipleAddressProvider {
    func makeAddress(from walletPublicKey: Data) throws -> String
    func validate(_ address: String) -> Bool
}


extension AddressService {
    public func makeAddresses(from walletPublicKey: Data) throws -> [Address] {
        let address = try makeAddress(from: walletPublicKey)
        return [PlainAddress(value: address)]
    }
}
