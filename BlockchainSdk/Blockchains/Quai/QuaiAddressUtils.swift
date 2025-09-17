//
//  QuaiAddressUtils.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

// MARK: - Quai Address Derivation

struct QuaiAddressUtils {
    // MARK: - Private Properties

    private let addressService: EVMAddressService
    private let expectedZone: QuaiZoneType

    // MARK: - Init

    init(addressService: EVMAddressService, expectedZone: QuaiZoneType) {
        self.addressService = addressService
        self.expectedZone = expectedZone
    }

    // MARK: - Implementation

    func derive(extendendPublicKey: ExtendedPublicKey, with addressType: AddressType) throws -> Address {
        for attempt in 0 ..< Constants.maxDerivationAttempts {
            let derivedKey = try extendendPublicKey.derivePublicKey(node: .nonHardened(UInt32(attempt)))

            let zoneAddress = try addressService.makeAddress(
                for: .init(seedKey: derivedKey.publicKey, derivationType: .none),
                with: addressType
            )

            if checkAddressZone(address: zoneAddress.value, expectedZone: expectedZone) {
                return zoneAddress
            }
        }

        throw BlockchainSdkError.addressesIsEmpty
    }

    private func checkAddressZone(address: String, expectedZone: QuaiZoneType) -> Bool {
        let addressBytes = Data(hex: address)
        let zoneBits = addressBytes[0] & 0x3F // 6 low bits

        switch expectedZone {
        case .cyprus1: return zoneBits == 0x00
        case .cyprus2: return zoneBits == 0x01
        case .cyprus3: return zoneBits == 0x02
        case .paxos1: return zoneBits == 0x10
        case .paxos2: return zoneBits == 0x11
        case .paxos3: return zoneBits == 0x12
        case .hydra1: return zoneBits == 0x20
        case .hydra2: return zoneBits == 0x21
        case .hydra3: return zoneBits == 0x22
        }
    }
}

extension QuaiAddressUtils {
    enum Constants {
        static let maxDerivationAttempts: UInt32 = 10_000_000
    }
}
