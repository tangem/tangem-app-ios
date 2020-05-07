//
//  AddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public protocol AddressService {
    func makeAddress(from walletPublicKey: Data) -> String
    func validate(_ address: String) -> Bool
}
