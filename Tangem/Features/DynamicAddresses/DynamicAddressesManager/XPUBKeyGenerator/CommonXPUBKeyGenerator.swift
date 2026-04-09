//
//  CommonXPUBKeyGenerator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemSdk

struct CommonXPUBKeyGenerator {
    let keysProvider: KeysRepository
    let keysDerivingInteractor: KeysDeriving
    let tokenItem: TokenItem
}

// MARK: - XPUBKeyGenerator

extension CommonXPUBKeyGenerator: XPUBKeyGenerator {
    func derivationIsNeeded() -> Bool {
        do {
            let xpubPaths = try xpubDerivationPaths()
            let masterKey = try masterKey()

            let hasNotChild = masterKey.derivedKeys[xpubPaths.child] == nil
            let hasNotParent = masterKey.derivedKeys[xpubPaths.parent] == nil

            return hasNotChild || hasNotParent
        } catch {
            return true
        }
    }

    func generateXPUBKey() async throws -> Wallet.PublicKey.XPUBKey {
        if let xpubKey = try xpubKey() {
            // Already have. No derivation needed
            return xpubKey
        }

        let masterKey = try masterKey()
        let paths = try xpubDerivationPaths()

        let derivationResult = try await keysDerivingInteractor.deriveKeys(
            derivations: [masterKey.publicKey: [paths.child, paths.parent]]
        )

        keysProvider.update(derivations: derivationResult)

        guard let xpubKey = try xpubKey() else {
            throw Error.failedToCreateXPUBKey
        }

        return xpubKey
    }
}

// MARK: - Private

private extension CommonXPUBKeyGenerator {
    func xpubKey() throws -> Wallet.PublicKey.XPUBKey? {
        let masterKey = try masterKey()
        let xpubPaths = try xpubDerivationPaths()

        guard let child = masterKey.derivedKeys[xpubPaths.child],
              let parent = masterKey.derivedKeys[xpubPaths.parent] else {
            // Has not derivations
            return nil
        }

        return Wallet.PublicKey.XPUBKey(
            child: .init(path: xpubPaths.child, extendedPublicKey: child),
            parent: .init(path: xpubPaths.parent, extendedPublicKey: parent)
        )
    }

    func xpubDerivationPaths() throws -> (child: DerivationPath, parent: DerivationPath) {
        guard let derivationPath = tokenItem.blockchainNetwork.derivationPath else {
            throw Error.derivationPathNotFound
        }

        return try XPUBUtils.xpubDerivationPaths(for: derivationPath)
    }

    func masterKey() throws -> KeyInfo {
        guard let masterKey = keysProvider.keys.first(where: { $0.curve == tokenItem.blockchain.curve }) else {
            throw Error.masterKeyNotFound
        }

        return masterKey
    }
}

// MARK: - Error

extension CommonXPUBKeyGenerator {
    enum Error: String, LocalizedError {
        case derivationPathNotFound
        case masterKeyNotFound
        case failedToCreateXPUBKey

        var errorDescription: String? {
            switch self {
            case .derivationPathNotFound: "Derivation path not found."
            case .masterKeyNotFound: "Master key not found."
            case .failedToCreateXPUBKey: "Failed to create XPUB key."
            }
        }
    }
}
