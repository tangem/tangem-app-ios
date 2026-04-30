//
//  LitecoinAddressService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct LitecoinAddressService {
    let legacy: BitcoinLegacyAddressService
    let bech32: BitcoinBech32AddressService

    init(networkParams: UTXONetworkParams) {
        legacy = BitcoinLegacyAddressService(networkParams: networkParams)
        bech32 = BitcoinBech32AddressService(networkParams: networkParams)
    }
}

// MARK: - AddressValidator

extension LitecoinAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        legacy.validate(address) || bech32.validate(address)
    }
}

// MARK: - AddressProvider

extension LitecoinAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        switch addressType {
        case .default, .used(.default, _):
            return try bech32.makeAddress(for: publicKey, with: addressType)
        case .legacy, .used(.legacy, _):
            return try legacy.makeAddress(for: publicKey, with: addressType)
        case .used:
            throw AddressTypeError.notSupported
        }
    }
}
