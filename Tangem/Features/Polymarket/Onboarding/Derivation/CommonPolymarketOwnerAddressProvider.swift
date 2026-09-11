//
//  CommonPolymarketOwnerAddressProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemPolymarket
import TangemSdk

final class CommonPolymarketOwnerAddressProvider {
    private let keysRepository: KeysRepository
    private let keysDerivingInteractor: any KeysDeriving
    private let areHDWalletsSupported: Bool

    init(
        keysRepository: KeysRepository,
        keysDerivingInteractor: any KeysDeriving,
        areHDWalletsSupported: Bool
    ) {
        self.keysRepository = keysRepository
        self.keysDerivingInteractor = keysDerivingInteractor
        self.areHDWalletsSupported = areHDWalletsSupported
    }
}

// MARK: - PolymarketOwnerAddressProviding protocol conformance

extension CommonPolymarketOwnerAddressProvider: PolymarketOwnerAddressProviding {
    func getOwnerAddress() -> String? {
        guard let storedKey = PolymarketUtilities.getKey(from: keysRepository) else {
            return nil
        }

        return try? makeAddress(using: storedKey)
    }

    func deriveOwnerAddress() async throws(PolymarketDerivationError) -> String {
        if let storedKey = PolymarketUtilities.getKey(from: keysRepository) {
            return try makeAddress(using: storedKey)
        }

        guard
            let masterKey = try? keysRepository.masterKey(curve: PolymarketUtilities.mandatoryCurve),
            let walletPublicKey = masterKey.publicKey
        else {
            throw .missingWallet
        }

        guard areHDWalletsSupported else {
            throw .derivationUnsupported
        }

        let derivedKey = try await deriveKey(for: walletPublicKey)

        return try makeAddress(using: PolymarketUtilities.makePublicKey(seedKey: walletPublicKey, derivedKey: derivedKey))
    }
}

// MARK: - Private implementation

private extension CommonPolymarketOwnerAddressProvider {
    func deriveKey(for walletPublicKey: Data) async throws(PolymarketDerivationError) -> ExtendedPublicKey {
        let path = PolymarketUtilities.derivationPath
        let derivations: DerivationResult

        do {
            derivations = try await keysDerivingInteractor.deriveKeys(derivations: [walletPublicKey: [path]])
        } catch {
            PolymarketLogger.error("Failed to derive the owner key", error: error)
            throw PolymarketDerivationError(derivationFailure: error)
        }

        keysRepository.update(derivations: derivations)

        guard let derivedKey = derivations[walletPublicKey]?[path] else {
            PolymarketLogger.error("Derivation succeeded but returned no key", error: PolymarketDerivationError.keyNotDerived)
            throw .keyNotDerived
        }

        return derivedKey
    }

    func makeAddress(using ownerKey: Wallet.PublicKey) throws(PolymarketDerivationError) -> String {
        do {
            return try PolymarketUtilities.makeAddress(using: ownerKey)
        } catch {
            PolymarketLogger.error("Failed to make the owner address", error: error)
            throw .addressCreationFailed
        }
    }
}
