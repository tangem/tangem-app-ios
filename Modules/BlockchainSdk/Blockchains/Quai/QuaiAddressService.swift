//
//  QuaiAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct QuaiAddressService {
    private let evmAddressService = EVMAddressService()
    private let expectedZone: QuaiZoneType = .cyprus1
}

// MARK: - AddressProvider

extension QuaiAddressService: AddressProvider {
    public func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        try evmAddressService.makeAddress(for: publicKey, with: addressType)
    }
}

// MARK: - AddressValidator

extension QuaiAddressService: AddressValidator {
    public func validate(_ address: String) -> Bool {
        if EthereumAddressUtils.isValidAddressHex(value: address), isAddressZoneValid(address: address) {
            return true
        }

        return false
    }

    // MARK: - Private Implementation

    func isAddressZoneValid(address: String) -> Bool {
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
            let hasCorrectFirstByte = firstByte == expectedZone.cyprus1FirstByte
            let ninthBit = (secondByte & expectedZone.cyprus1NinthBitMask) == 0
            return hasCorrectFirstByte && ninthBit
        }
    }
}

// MARK: - Constants

extension QuaiAddressService {
    enum Constants {
        static let expectedZone: QuaiZoneType = .cyprus1
    }
}
