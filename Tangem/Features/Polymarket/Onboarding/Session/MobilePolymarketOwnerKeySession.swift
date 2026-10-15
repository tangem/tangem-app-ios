//
//  MobilePolymarketOwnerKeySession.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation
import TangemMobileWalletSdk
import TangemPolymarket
import TangemSdk

final class MobilePolymarketOwnerKeySession {
    private let userWalletId: UserWalletId
    private let config: UserWalletConfig
    private let keysRepository: KeysRepository
    private let mobileWalletSdk: MobileWalletSdk

    init(
        userWalletId: UserWalletId,
        config: UserWalletConfig,
        keysRepository: KeysRepository,
        mobileWalletSdk: MobileWalletSdk = CommonMobileWalletSdk()
    ) {
        self.userWalletId = userWalletId
        self.config = config
        self.keysRepository = keysRepository
        self.mobileWalletSdk = mobileWalletSdk
    }
}

// MARK: - PolymarketOwnerKeySession protocol conformance

extension MobilePolymarketOwnerKeySession: PolymarketOwnerKeySession {
    func derive<Output>(
        andRun work: @escaping (PolymarketOwnerKeySessionContext) async throws -> Output
    ) async throws -> Output {
        let seedKey = try PolymarketUtilities.sessionSeedKey(from: keysRepository, config: config)
        let context = try await unlock()
        let ownerKey = try deriveOwnerKey(seedKey: seedKey, context: context)

        let sessionContext = try PolymarketOwnerKeySessionContext(
            ownerKey: ownerKey,
            keysRepository: keysRepository,
            signer: UnlockedSigner(mobileWalletSdk: mobileWalletSdk, context: context)
        )

        return try await work(sessionContext)
    }
}

// MARK: - Private implementation

private extension MobilePolymarketOwnerKeySession {
    func unlock() async throws(PolymarketOnboardingError) -> MobileWalletContext {
        do {
            return try await MobileAuthUtil(
                userWalletId: userWalletId,
                config: config,
                biometricsProvider: CommonUserWalletBiometricsProvider()
            )
            .unlockedContext()
        } catch is CancellationError {
            throw .derivation(.cancelled)
        } catch {
            PolymarketLogger.error("Failed to unlock the wallet for the owner key", error: error)
            throw .derivation(PolymarketDerivationError(derivationFailure: error))
        }
    }

    func deriveOwnerKey(
        seedKey: Data,
        context: MobileWalletContext
    ) throws(PolymarketOnboardingError) -> Wallet.PublicKey {
        let path = PolymarketUtilities.derivationPath
        let derivations: DerivationResult

        do {
            derivations = try mobileWalletSdk
                .deriveKeys(context: context, derivationPaths: [seedKey: [path]])
                .reduce(into: [:]) { partialResult, keyInfo in
                    partialResult[keyInfo.key] = .init(keys: keyInfo.value.derivedKeys)
                }
        } catch {
            PolymarketLogger.error("Failed to derive the owner key", error: error)
            throw .derivation(PolymarketDerivationError(derivationFailure: error))
        }

        keysRepository.update(derivations: derivations)

        guard let derivedKey = derivations[seedKey]?[path] else {
            PolymarketLogger.error("Derivation succeeded but returned no key", error: PolymarketDerivationError.keyNotDerived)
            throw .derivation(.keyNotDerived)
        }

        return PolymarketUtilities.makePublicKey(seedKey: seedKey, derivedKey: derivedKey)
    }
}

// MARK: - Signer

private struct UnlockedSigner: PolymarketOwnerKeySigner {
    let mobileWalletSdk: MobileWalletSdk
    let context: MobileWalletContext

    func sign(hashes: [Data], ownerKey: Wallet.PublicKey) async throws -> [SignatureInfo] {
        let dataToSign = SignData(
            derivationPath: ownerKey.derivationPath,
            hashes: hashes,
            publicKey: ownerKey.blockchainKey
        )

        return try mobileWalletSdk
            .sign(dataToSign: [dataToSign], seedKey: ownerKey.seedKey, context: context)
            .map { SignatureInfo(signature: $0.signature, publicKey: $0.publicKey, hash: $0.hash) }
    }
}
