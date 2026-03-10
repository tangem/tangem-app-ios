//
//  WalletFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct WalletFactory {
    private let blockchain: Blockchain
    private let addressService: AddressService

    init(blockchain: Blockchain) {
        self.blockchain = blockchain
        addressService = AddressServiceFactory(blockchain: blockchain).makeAddressService()
    }

    /// With one public key
    func makeWallet(publicKey: Wallet.PublicKey) throws -> Wallet {
        let defaultAddress = try addressService.makeAddress(for: publicKey, with: .default)
        let legacyAddress = try makeLegacyAddressIfNeeded(publicKey: publicKey)

        let addressesProvider = CommonAddressesProvider(defaultAddress: defaultAddress, legacyAddress: legacyAddress)
        return Wallet(blockchain: blockchain, addressesProvider: addressesProvider)
    }

    /// With multisig script public key
    func makeWallet(publicKey: Wallet.PublicKey, pairPublicKey: Data) throws -> Wallet {
        guard let addressService = addressService as? BitcoinScriptAddressesProvider else {
            throw WalletFactoryError.bitcoinScriptAddressesProviderNotFound
        }

        let addresses = try addressService.makeAddresses(publicKey: publicKey, pairPublicKey: pairPublicKey)
        let defaultAddress = addresses.first(where: { $0.type == .default })
        let legacyAddress = addresses.first(where: { $0.type == .legacy })

        guard let defaultAddress else {
            throw WalletFactoryError.defaultAddressNotFound
        }

        let addressesProvider = CommonAddressesProvider(defaultAddress: defaultAddress, legacyAddress: legacyAddress)
        return Wallet(blockchain: blockchain, addressesProvider: addressesProvider)
    }

    private func makeLegacyAddressIfNeeded(publicKey: Wallet.PublicKey) throws -> Address? {
        guard AddressTypesConfig().hasLegacy(for: blockchain) else {
            return nil
        }

        return try addressService.makeAddress(for: publicKey, with: .legacy)
    }
}

enum WalletFactoryError: LocalizedError {
    case defaultAddressNotFound
    case bitcoinScriptAddressesProviderNotFound
}
