//
//  DynamicAddressesProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct DynamicAddressesProvider {
    private let seedKey: Data
    private let xpubKey: Wallet.PublicKey.XPUBKey
    private let addressProvider: AddressProvider
    private let supportedAddressTypes: [AddressType]
    private var _defaultAddress: Address
    private var _changeAddress: Address

    private var userAddresses: [UTXOUsedAddress: any Address] = [:]

    init(
        seedKey: Data,
        xpubKey: Wallet.PublicKey.XPUBKey,
        addressProvider: AddressProvider,
        supportedAddressTypes: [AddressType],
        defaultAddress: Address,
    ) {
        self.seedKey = seedKey
        self.xpubKey = xpubKey
        self.addressProvider = addressProvider
        self.supportedAddressTypes = supportedAddressTypes

        _defaultAddress = defaultAddress
        _changeAddress = defaultAddress
    }
}

// MARK: - Wallet.AddressesProvider

extension DynamicAddressesProvider: Wallet.AddressesProvider {
    var addresses: [any Address] {
        [defaultAddress] + userAddresses.values
    }

    /// Computes first unused receive address
    /// Returns base address (0/0) when usedDerivations is empty or on error.
    var defaultAddress: any Address { _defaultAddress }

    /// Computes first unused change address
    var changeAddress: any Address { _changeAddress }

    mutating func update(address: any Address) {}
    mutating func update(usedAddresses: [UTXOUsedAddress]) {
        let usedDerivations = usedAddresses.map(\.derivationPath.rawPath)
        BSDKLogger.debug("Used dynamic addresses paths: \(usedDerivations)")

        do {
            userAddresses = try usedAddresses.reduce(into: [:]) { partialResult, address in
                partialResult[address] = try makeUsedAddress(for: address)
            }
            recalculateAddresses()
        } catch {
            assertionFailure("Creating dynamic address error: \(error.localizedDescription)")
            BSDKLogger.error(error: error)
        }
    }
}

// MARK: - Private

private extension DynamicAddressesProvider {
    mutating func recalculateAddresses() {
        _defaultAddress = resolveAddress(for: .external)
        _changeAddress = resolveAddress(for: .internal)
    }

    func resolveAddress(for chain: XPUBAddressesDerivationHelper.Chain) -> Address {
        let accountLevelDerivationPath = xpubKey.child.path
        let usedDerivations = Array(userAddresses.keys.map(\.derivationPath))

        let helper = XPUBAddressesDerivationHelper(
            accountDerivationPath: accountLevelDerivationPath,
            usedDerivations: usedDerivations
        )

        let derivationPath = helper.resolveDerivationPath(chain: chain)
        let nodes = derivationPath.nodes
        let chainNode = nodes[nodes.count - 2]
        let addressNode = nodes[nodes.count - 1]

        do {
            return try makeAddress(chainNode: chainNode, addressNode: addressNode, type: .default)
        } catch {
            assertionFailure("Creating dynamic address error: \(error.localizedDescription)")
            return _defaultAddress
        }
    }

    func makeAddress(chainNode: DerivationNode, addressNode: DerivationNode, type: AddressType) throws -> Address {
        // Derive the child public key from the account XPUB using the last two nodes (chain/index)
        let accountLevelPublicKey = xpubKey.child.extendedPublicKey
        let chainKey = try accountLevelPublicKey.derivePublicKey(node: chainNode)
        let derivedKey = try chainKey.derivePublicKey(node: addressNode)

        let nodes = xpubKey.child.path.nodes + [chainNode, addressNode]
        let derivationPath = DerivationPath(nodes: nodes)

        let hdKey = Wallet.PublicKey.HDKey(path: derivationPath, extendedPublicKey: derivedKey)
        let derivedPublicKey = Wallet.PublicKey(seedKey: seedKey, derivationType: .plain(hdKey))
        return try addressProvider.makeAddress(for: derivedPublicKey, with: type)
    }

    func makeUsedAddress(for address: UTXOUsedAddress) throws -> Address {
        let type = addressType(for: address.scriptType)

        // Important:
        // Take only the (chain, index) suffix from the used address — the
        // account-level prefix comes from the wallet's xpub.
        //
        // Why:
        // The derivation path from `UTXOUsedAddress` may come under a
        // different BIP purpose than `xpubKey`. E.g. BlockBook returns
        // p2pkh paths under BIP-44, while Wallet 2 derives `xpubKey` under
        // BIP-84 (per `DerivationConfigV3`).
        //
        // If we used `address.derivationPath` on `Wallet.PublicKey.HDKey`
        // and made an address with this HDKey,
        // `BitcoinWalletManager.mapToSignData` would emit `SignData` with a
        // BIP-84 `publicKey` and a BIP-44 `derivationPath`. The signer would
        // derive a BIP-44 private key from `seedKey`, which does not match
        // the BIP-84 public key — invalid signature, broadcast fails.

        let derivationPath = address.derivationPath
        let nodes = derivationPath.nodes
        let chainNode = nodes[nodes.count - 2]
        let addressNode = nodes[nodes.count - 1]

        let path = [chainNode, addressNode].map(\.pathDescription).joined(separator: "/")

        return try makeAddress(chainNode: chainNode, addressNode: addressNode, type: .used(type, path: path))
    }

    func addressType(for scriptType: UTXOXpubScriptType) -> AddressType {
        switch scriptType {
        case .p2pkh where supportedAddressTypes.contains(where: \.isLegacy):
            return .legacy
        case .p2pkh, .p2wpkh:
            return .default
        }
    }
}
