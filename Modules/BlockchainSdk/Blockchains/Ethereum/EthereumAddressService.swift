//
//  EthereumAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import CryptoSwift

struct EthereumAddressService {
    private let evmAddressService = EVMAddressService()
    private let ensProcessor: ENSProcessor

    init(ensProcessor: ENSProcessor) {
        self.ensProcessor = ensProcessor
    }
}

// MARK: - AddressProvider

@available(iOS 13.0, *)
extension EthereumAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        try evmAddressService.makeAddress(for: publicKey, with: addressType)
    }
}

// MARK: - AddressValidator

@available(iOS 13.0, *)
extension EthereumAddressService: AddressValidator {
    /// Checks if the given address string is a valid Ethereum address or a valid ENS name.
    ///
    /// - Parameter address: The address string to validate. Can be a hex address (with 0x prefix) or an ENS name.
    /// - Returns: `true` if the address is a valid hex address (with or without checksum), or a valid ENS name; otherwise, `false`.
    func validate(_ address: String) -> Bool {
        if evmAddressService.validate(address) {
            return true
        } else {
            // Fallback valid ENS value address from AddressResolver protocol
            let encodeData = try? ensProcessor.encode(name: address)
            return !(encodeData?.isEmpty ?? true)
        }
    }
}
