//
//  AddressBlockchainResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct AddressBlockchainResolver {
    func resolve(address: String, blockchains: [Blockchain]) -> Set<Blockchain> {
        var matchingBlockchains = Set<Blockchain>()

        for blockchain in blockchains {
            if case .near = blockchain, !NEARAddressUtil.isImplicitAccount(accountId: address) {
                continue
            }

            let addressService = AddressServiceFactory(blockchain: blockchain).makeAddressService()

            if addressService.validate(address) {
                matchingBlockchains.insert(blockchain)
            }
        }

        return matchingBlockchains
    }
}
