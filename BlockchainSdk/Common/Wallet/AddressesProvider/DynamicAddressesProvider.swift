//
//  DynamicAddressesProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemSdk

public struct DynamicAddressesProvider {
    private let seedKey: Data
    private let _defaultAddress: Address
    private let xpubKey: Wallet.PublicKey.XPUBKey
    private let addressProvider: AddressProvider

    private var usedDerivations: [DerivationPath] = []

    public init(
        seedKey: Data,
        defaultAddress: Address,
        xpubKey: Wallet.PublicKey.XPUBKey,
        addressProvider: AddressProvider
    ) {
        self.seedKey = seedKey
        _defaultAddress = defaultAddress
        self.xpubKey = xpubKey
        self.addressProvider = addressProvider
    }

    /// Should be called when used derivation paths arrive from Blockbook XPUB response.
    public mutating func update(usedDerivationPaths: [DerivationPath]) {
        usedDerivations = usedDerivationPaths
    }
}

// MARK: - Wallet.AddressesProvider

extension DynamicAddressesProvider: Wallet.AddressesProvider {
    /// Computes first unused receive address every call.
    /// Returns base address (0/0) when usedDerivations is empty or on error.
    public var defaultAddress: any Address {
        resolveAddress(for: .external)
    }

    public var legacyAddress: (any Address)? { nil }

    /// Computes first unused change address every call.
    public var changeAddress: any Address {
        resolveAddress(for: .internal)
    }

    public mutating func update(address: any Address) {}
}

// MARK: - Private

private extension DynamicAddressesProvider {
    func resolveAddress(for chain: DynamicAddressesDerivationHelper.Chain) -> Address {
        let accountLevelDerivationPath = xpubKey.child.path
        let helper = DynamicAddressesDerivationHelper(accountDerivationPath: accountLevelDerivationPath, usedDerivations: usedDerivations)
        let derivationPath = helper.resolveDerivationPath(chain: chain)

        do {
            return try makeAddress(at: derivationPath)
        } catch {
            assertionFailure("Creating dynamic address error: \(error.localizedDescription)")
            return _defaultAddress
        }
    }

    func makeAddress(at derivationPath: DerivationPath) throws -> Address {
        // Derive the child public key from the account XPUB using the last two nodes (chain/index)
        let nodes = derivationPath.nodes
        let chainNode = nodes[nodes.count - 2]
        let addressNode = nodes[nodes.count - 1]

        let accountLevelPublicKey = xpubKey.child.extendedPublicKey
        let chainKey = try accountLevelPublicKey.derivePublicKey(node: chainNode)
        let derivedKey = try chainKey.derivePublicKey(node: addressNode)

        let hdKey = Wallet.PublicKey.HDKey(path: derivationPath, extendedPublicKey: derivedKey)
        let derivedPublicKey = Wallet.PublicKey(seedKey: seedKey, derivationType: .plain(hdKey))
        return try addressProvider.makeAddress(for: derivedPublicKey, with: .default)
    }
}
