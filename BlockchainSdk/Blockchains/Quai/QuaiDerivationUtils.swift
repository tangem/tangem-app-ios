//
//  QuaiDerivationUtils.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

// MARK: - Quai Address Derivation

public struct QuaiDerivationUtils {
    // MARK: - Private Properties

    private let addressService = QuaiAddressService()

    // MARK: - Init

    public init() {}

    // MARK: - Public Implementation

    public func derive(extendedPublicKey: ExtendedPublicKey, with addressType: AddressType) throws -> (
        key: ExtendedPublicKey,
        node: DerivationNode
    ) {
        for attempt in 0 ..< Constants.maxDerivationAttempts {
            let derivedNode: DerivationNode = .nonHardened(UInt32(attempt))
            let derivedKey = try extendedPublicKey.derivePublicKey(node: derivedNode)

            let zoneAddress = try addressService.makeAddress(
                for: .init(seedKey: derivedKey.publicKey, derivationType: .none),
                with: addressType
            )

            if addressService.isAddressZoneValid(address: zoneAddress.value) {
                return (derivedKey, derivedNode)
            }
        }

        throw BlockchainSdkError.addressesIsEmpty
    }
}

extension QuaiDerivationUtils {
    enum Constants {
        /// https://github.com/dominant-strategies/quais.js/blob/master/src/wallet/bip44/bip44.ts#L18
        static let maxDerivationAttempts: UInt32 = 10_000_000
    }
}
