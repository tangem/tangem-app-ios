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
    /// Validates a plain address against provided blockchains and returns every matching one.
    /// For EVM chains, validation is executed once and reused for all EVM-compatible networks.
    func resolve(address: String, blockchains: [Blockchain]) -> Set<Blockchain> {
        MainQRScanLogger.debug(
            MainQRScanLoggerStrings.addressResolverStarted(
                addressLength: address.count,
                blockchains: blockchains.count
            )
        )

        var matchingBlockchains = Set<Blockchain>()
        var validationCache: [String: Bool] = [:]

        for blockchain in blockchains {
            let validationKey = blockchain.isEvm ? "evm" : "blockchain:\(blockchain.codingKey)"

            let isValid: Bool
            if let cachedResult = validationCache[validationKey] {
                isValid = cachedResult
            } else {
                let addressService = AddressServiceFactory(blockchain: blockchain).makeAddressService()
                isValid = addressService.validate(address)
                validationCache[validationKey] = isValid
            }

            if isValid {
                matchingBlockchains.insert(blockchain)
            }
        }

        MainQRScanLogger.debug(MainQRScanLoggerStrings.addressResolverFinished(matchedCount: matchingBlockchains.count))

        return matchingBlockchains
    }
}
