//
//  XPUBAddressesProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemSdk

public struct XPUBAddressesProvider {
    private let seedKey: Data
    private let plainHDKey: Wallet.PublicKey.HDKey
    private let xpubHDKey: Wallet.PublicKey.XPUBKey
    private let addressProvider: AddressProvider
    private let helper = XPUBAddressesHelper()

    /// Updated from Blockbook XPUB response
    private var usedDerivations: [DerivationPath] = []

    public init(
        seedKey: Data,
        plainHDKey: Wallet.PublicKey.HDKey,
        xpubHDKey: Wallet.PublicKey.XPUBKey,
        addressProvider: AddressProvider
    ) {
        self.seedKey = seedKey
        self.plainHDKey = plainHDKey
        self.xpubHDKey = xpubHDKey
        self.addressProvider = addressProvider
    }

    /// Called when used derivation paths arrive from Blockbook XPUB response.
    public mutating func update(usedDerivationPaths: [DerivationPath]) {
        usedDerivations = usedDerivationPaths
    }
}

// MARK: - Wallet.AddressesProvider

extension XPUBAddressesProvider: Wallet.AddressesProvider {
    public var addresses: [any Address] {
        [defaultAddress]
    }

    /// Computes first unused receive address every call.
    /// Returns base address (0/0) when usedDerivations is empty or on error.
    public var defaultAddress: any Address {
        resolveAddress(for: .external)
    }

    /// Computes first unused change address every call.
    public var changeAddress: any Address {
        resolveAddress(for: .internal)
    }

    public mutating func update(address: any Address) {}
}

// MARK: - Private

private extension XPUBAddressesProvider {
    func resolveAddress(for chain: XPUBAddressesHelper.Chain) -> Address {
        let derivationPath = helper.resolveDerivationPath(
            accountDerivationPath: xpubHDKey.child.path,
            chain: chain,
            usedDerivations: usedDerivations
        )

        do {
            return try makeAddress(at: derivationPath)
        } catch {
            assertionFailure("Creating dynamic address error: \(error.localizedDescription)")
            return EmptyAddress()
        }
    }

    func makeAddress(at derivationPath: DerivationPath) throws -> Address {
        // Derive the child public key from the account XPUB using the last two nodes (chain/index)
        let nodes = derivationPath.nodes
        let chainNode = nodes[nodes.count - 2]
        let addressNode = nodes[nodes.count - 1]

        let chainKey = try xpubHDKey.child.extendedPublicKey.derivePublicKey(node: chainNode)
        let derivedKey = try chainKey.derivePublicKey(node: addressNode)

        let hdKey = Wallet.PublicKey.HDKey(path: derivationPath, extendedPublicKey: derivedKey)
        let derivedPublicKey = Wallet.PublicKey(seedKey: seedKey, derivationType: .plain(hdKey))
        return try addressProvider.makeAddress(for: derivedPublicKey, with: .default)
    }
}
