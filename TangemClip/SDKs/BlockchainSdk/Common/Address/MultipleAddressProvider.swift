//
//  MultipleAddressProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public protocol MultipleAddressProvider {
    func makeAddresses(from walletPublicKey: Data) throws -> [Address]
}

public protocol MultisigAddressProvider {
    func makeAddresses(from walletPublicKey: Data, with pairPublicKey: Data) throws -> [Address]
}
