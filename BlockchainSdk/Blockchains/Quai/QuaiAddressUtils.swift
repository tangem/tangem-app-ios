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

public struct QuaiAddressUtils {
    // MARK: - Private Properties

    private let addressService = EVMAddressService()
    private let expectedZone: QuaiZoneType = .cyprus1

    // MARK: - Constants

    private static let cyprus1FirstByte: UInt8 = 0x00
    private static let cyprus1NinthBitMask: UInt8 = 0x01

    // MARK: - Init

    public init() {}

    // MARK: - Public Implementation

    public func derive(extendendPublicKey: ExtendedPublicKey, with addressType: AddressType) throws -> ExtendedPublicKey {
        for attempt in 0 ..< Constants.maxDerivationAttempts {
            let derivedKey = try extendendPublicKey.derivePublicKey(node: .nonHardened(UInt32(attempt)))

            let zoneAddress = try addressService.makeAddress(
                for: .init(seedKey: derivedKey.publicKey, derivationType: .none),
                with: addressType
            )

            if checkAddressZone(address: zoneAddress.value, expectedZone: expectedZone) {
                return derivedKey
            }
        }

        throw BlockchainSdkError.addressesIsEmpty
    }

    // MARK: - Private Implementation

    private func checkAddressZone(address: String, expectedZone: QuaiZoneType) -> Bool {
        let cleanAddress = address.removeHexPrefix()
        let addressBytes = Data(hexString: cleanAddress)

        // Check if address has at least 2 bytes
        guard addressBytes.count >= 2 else {
            return false
        }

        let firstByte = addressBytes[0]
        let secondByte = addressBytes[1]

        // Validate based on expected zone
        switch expectedZone {
        case .cyprus1:
            let hasCorrectFirstByte = firstByte == Self.cyprus1FirstByte
            let ninthBit = (secondByte & Self.cyprus1NinthBitMask) == 0
            return hasCorrectFirstByte && ninthBit
        case .cyprus2, .cyprus3, .paxos1, .paxos2, .paxos3, .hydra1, .hydra2, .hydra3:
            // For use must be implement. Now use only cyprus1
            return false
        }
    }
}

extension QuaiAddressUtils {
    enum Constants {
        static let maxDerivationAttempts: UInt32 = 10_000_000
    }
}
