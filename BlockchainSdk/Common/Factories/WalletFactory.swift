//
//  WalletFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct WalletFactory {
    private let blockchain: Blockchain
    private let addressService: AddressService

    public init(blockchain: Blockchain) {
        self.blockchain = blockchain
        addressService = AddressServiceFactory(blockchain: blockchain).makeAddressService()
    }

    /// With one public key
    public func makeWallet(publicKey: Wallet.PublicKey) throws -> Wallet {
        let addressesProvider = try makeAddressesProvider(publicKey: publicKey)
        return Wallet(blockchain: blockchain, publicKey: publicKey, addressesProvider: addressesProvider)
    }

    private func makeAddressesProvider(publicKey: Wallet.PublicKey) throws -> Wallet.AddressesProvider {
        let defaultAddress = try addressService.makeAddress(for: publicKey, with: .default)

        switch publicKey.derivationType {
        case .xpub(_, let xpubKey) where blockchain.isDynamicAddressesSupported:
            return DynamicAddressesProvider(
                seedKey: publicKey.seedKey,
                xpubKey: xpubKey,
                addressProvider: addressService,
                defaultAddress: defaultAddress,
            )
        default:
            let legacyAddress = try makeLegacyAddressIfNeeded(publicKey: publicKey)
            return CommonAddressesProvider(defaultAddress: defaultAddress, legacyAddress: legacyAddress)
        }
    }

    /// With multisig script public key
    public func makeWallet(publicKey: Wallet.PublicKey, pairPublicKey: Data) throws -> Wallet {
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
        return Wallet(blockchain: blockchain, publicKey: publicKey, addressesProvider: addressesProvider)
    }

    private func makeLegacyAddressIfNeeded(publicKey: Wallet.PublicKey) throws -> Address? {
        guard AddressTypesConfig().hasLegacy(for: blockchain) else {
            return nil
        }

        return try addressService.makeAddress(for: publicKey, with: .legacy)
    }
}

public enum WalletFactoryError: LocalizedError {
    case defaultAddressNotFound
    case bitcoinScriptAddressesProviderNotFound

    public var errorDescription: String? {
        switch self {
        case .defaultAddressNotFound: "Default address not found"
        case .bitcoinScriptAddressesProviderNotFound: "Bitcoin script addresses provider not found"
        }
    }
}
