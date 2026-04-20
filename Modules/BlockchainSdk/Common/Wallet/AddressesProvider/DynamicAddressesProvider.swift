//
//  DynamicAddressesProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct DynamicAddressesProvider {
    private let seedKey: Data
    private let xpubKey: Wallet.PublicKey.XPUBKey
    private let addressProvider: AddressProvider

    private var _defaultAddress: Address
    private var _changeAddress: Address {
        didSet { print("->> \(_changeAddress)") } // DFmga5nmNZrwHaekZ5CBoLwdGERgBznERq
    }

    private var userAddresses: [DerivationPath: any Address] = [:]

    public init(
        seedKey: Data,
        xpubKey: Wallet.PublicKey.XPUBKey,
        addressProvider: AddressProvider,
        defaultAddress: Address,
    ) {
        self.seedKey = seedKey
        self.xpubKey = xpubKey
        self.addressProvider = addressProvider

        _defaultAddress = defaultAddress
        _changeAddress = defaultAddress
    }
}

// MARK: - Wallet.AddressesProvider

extension DynamicAddressesProvider: Wallet.AddressesProvider {
    public var addresses: [any Address] {
        [defaultAddress] + userAddresses.values
    }

    /// Computes first unused receive address
    /// Returns base address (0/0) when usedDerivations is empty or on error.
    public var defaultAddress: any Address { _defaultAddress }

    /// Computes first unused change address
    public var changeAddress: any Address { _changeAddress }

    public mutating func update(address: any Address) {}
    public mutating func update(userDerivations: [DerivationPath]) {
        BSDKLogger.debug("Used dynamic addresses paths: \(userDerivations.map(\.rawPath))")

        do {
            userAddresses = try userDerivations.reduce(into: [:]) { partialResult, derivationPath in
                let index = derivationPath.nodes.last?.pathDescription ?? "n/a"
                partialResult[derivationPath] = try makeAddress(at: derivationPath, type: .used(.default, index: index))
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
        let usedDerivations = Array(userAddresses.keys)

        let helper = XPUBAddressesDerivationHelper(
            accountDerivationPath: accountLevelDerivationPath,
            usedDerivations: usedDerivations
        )
        let derivationPath = helper.resolveDerivationPath(chain: chain)

        do {
            return try makeAddress(at: derivationPath, type: .default)
        } catch {
            assertionFailure("Creating dynamic address error: \(error.localizedDescription)")
            return _defaultAddress
        }
    }

    func makeAddress(at derivationPath: DerivationPath, type: AddressType) throws -> Address {
        // Derive the child public key from the account XPUB using the last two nodes (chain/index)
        let nodes = derivationPath.nodes
        let chainNode = nodes[nodes.count - 2]
        let addressNode = nodes[nodes.count - 1]

        let accountLevelPublicKey = xpubKey.child.extendedPublicKey
        let chainKey = try accountLevelPublicKey.derivePublicKey(node: chainNode)
        let derivedKey = try chainKey.derivePublicKey(node: addressNode)

        let hdKey = Wallet.PublicKey.HDKey(path: derivationPath, extendedPublicKey: derivedKey)
        let derivedPublicKey = Wallet.PublicKey(seedKey: seedKey, derivationType: .plain(hdKey))
        return try addressProvider.makeAddress(for: derivedPublicKey, with: type)
    }
}
