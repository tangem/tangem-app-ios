//
//  AddressBookAddressesHelper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct AddressBookAddressesHelper {
    let supportedBlockchains: [Blockchain]

    func groupByNetworkId(_ addresses: [AddressBookAddress]) -> [AddressBookAddress: [Blockchain]] {
        addresses.reduce(into: [:]) { partialResult, address in
            if let blockchain = supportedBlockchains.first(where: { $0.networkId == address.networkId }) {
                partialResult[address, default: []].append(blockchain)
            } else {
                assertionFailure("SupportedBlockchains doesn't contain blockchain for address: \(address.address)")
            }
        }
    }
}
