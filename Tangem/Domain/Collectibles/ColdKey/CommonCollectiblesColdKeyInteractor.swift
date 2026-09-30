//
//  CommonCollectiblesColdKeyInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemCollectibles
import BlockchainSdk
import TangemSdk
import TangemFoundation

/// A card derives the cold key and signs in the same NFC session; a mobile wallet derives without a session
/// at all, so there is nothing to fold and it signs with the key it holds.
final class CommonCollectiblesColdKeyInteractor {
    private let config: UserWalletConfig
    private let keysRepository: KeysRepository
    private let keysDeriving: KeysDeriving
    private let signer: TangemSigner

    private var curve: EllipticCurve {
        CollectiblesAccountKeyPath.curve(for: config.derivationStyle)
    }

    init(
        config: UserWalletConfig,
        keysRepository: KeysRepository,
        keysDeriving: KeysDeriving,
        signer: TangemSigner
    ) {
        self.config = config
        self.keysRepository = keysRepository
        self.keysDeriving = keysDeriving
        self.signer = signer
    }
}

// MARK: - CollectiblesColdKeyInteractor protocol conformance

extension CommonCollectiblesColdKeyInteractor: CollectiblesColdKeyInteractor {
    /// Standalone because the chain cannot be read until this key exists — the vault's address derives from it.
    func derive() async throws {
        let derivations = try await keysDeriving
            .deriveKeys(derivations: [try seedKey(): [CollectiblesAccountKeyPath.derivationPath]])

        keysRepository.update(derivations: derivations)
    }

    func sign(message: Data, coldKey: Wallet.PublicKey) async throws -> Data {
        guard keysDeriving.requiresCard else {
            return try await signWithHeldKey(message: message, coldKey: coldKey)
        }

        return try await deriveAndSign(message: message, coldOwner: coldKey.blockchainKey)
    }
}

// MARK: - Private implementation

private extension CommonCollectiblesColdKeyInteractor {
    /// Re-derives a key already held — free inside the session the signature needs, and it restores a lost copy.
    func deriveAndSign(message: Data, coldOwner: Data) async throws -> Data {
        let task = CollectiblesDeriveAndSignTask(seedKey: try seedKey(), message: message)
            .withUserWalletRegistration()
        let tangemSdk = config.makeTangemSdk()

        let response: CollectiblesDeriveAndSignTask.Response = try await withCheckedThrowingContinuation { continuation in
            tangemSdk.startSession(with: task, filter: config.cardSessionFilter) { result in
                withExtendedLifetime(task) {}
                continuation.resume(with: result)
            }
        }

        guard response.coldOwner == coldOwner else {
            throw ColdKeyError.coldOwnerMismatch
        }

        keysRepository.update(derivations: response.derivationResult)

        return response.signature
    }

    func signWithHeldKey(message: Data, coldKey: Wallet.PublicKey) async throws -> Data {
        let signatureInfo = try await signer
            .sign(hash: message, walletPublicKey: coldKey)
            .async()

        return signatureInfo.signature
    }

    func seedKey() throws -> Data {
        try keysRepository.masterKeyPublicKey(curve: curve)
    }
}

// MARK: - Error

private extension CommonCollectiblesColdKeyInteractor {
    enum ColdKeyError: Error {
        case coldOwnerMismatch
    }
}
