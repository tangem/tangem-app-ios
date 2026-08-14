//
//  JointAccountMobileWalletDerivationInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSdk
import TangemFoundation
import TangemMobileWalletSdk

/// - Note: Deriving and signing share one unlocked context, so creating an account asks the user once — what the card
/// path spends a single tap on.
struct JointAccountMobileWalletDerivationInteractor {
    let userWalletId: UserWalletId
    let userWalletConfig: UserWalletConfig
    let keysRepository: KeysRepository
    let mobileWalletSdk: MobileWalletSdk
}

// MARK: - JointAccountDerivationInteractor protocol conformance

extension JointAccountMobileWalletDerivationInteractor: JointAccountDerivationInteractor {
    func deriveAndSign<Builder: JointAccountPayloadBuilder>(
        derivationIndex: Int,
        payloadBuilder: Builder
    ) async throws -> JointAccountDerivationInteractorResult<Builder.Payload> {
        let derivationPath = JointAccountKeyPath.derivationPath(forAccountAtIndex: derivationIndex)
        let seedKey = try keysRepository.masterKeyPublicKey(curve: JointAccountKeyPath.blockchain.curve)
        let context = try await unlock()

        let derivedKey = try derivedKey(at: derivationPath, seedKey: seedKey, in: context)
        let payload = payloadBuilder.makePayload(address: derivedKey.address, derivationIndex: derivationIndex)

        let signature = try sign(
            digest: JointAccountDerivationUtils.digest(payload: payload),
            with: derivedKey,
            seedKey: seedKey,
            in: context
        )

        return JointAccountDerivationInteractorResult(
            payload: payload,
            derivedKey: derivedKey,
            signature: signature
        )
    }
}

// MARK: - Private

private extension JointAccountMobileWalletDerivationInteractor {
    /// - Throws: `CancellationError` when the user declines, which is not a failure to report to them.
    func unlock() async throws -> MobileWalletContext {
        let authUtil = MobileAuthUtil(
            userWalletId: userWalletId,
            config: userWalletConfig,
            biometricsProvider: CommonUserWalletBiometricsProvider()
        )

        switch try await authUtil.unlock() {
        case .successful(let context):
            return context
        case .canceled, .userWalletNeedsToDelete:
            throw CancellationError()
        }
    }

    func derivedKey(
        at derivationPath: DerivationPath,
        seedKey: Data,
        in context: MobileWalletContext
    ) throws -> JointAccountDerivedKey {
        if let derivedKey = try storedDerivedKey(at: derivationPath) {
            return derivedKey
        }

        let derived = try mobileWalletSdk.deriveKeys(context: context, derivationPaths: [seedKey: [derivationPath]])
        let derivationResult: DerivationResult = derived.reduce(into: [:]) { partialResult, keyInfo in
            partialResult[keyInfo.key] = .init(keys: keyInfo.value.derivedKeys)
        }

        keysRepository.update(derivations: derivationResult)

        guard let extendedPublicKey = derivationResult[seedKey]?[derivationPath] else {
            throw Error.keyNotDerived
        }

        return try JointAccountDerivationUtils.makeDerivedKey(
            seedKey: seedKey,
            derivationPath: derivationPath,
            extendedPublicKey: extendedPublicKey
        )
    }

    /// Reads the keys repository anew on every call: `KeyInfo` is a value, so a copy taken before
    /// `update(derivations:)` never gains the key that was just derived.
    func storedDerivedKey(at derivationPath: DerivationPath) throws -> JointAccountDerivedKey? {
        let masterKey = try keysRepository.masterKey(curve: JointAccountKeyPath.blockchain.curve)

        guard let extendedPublicKey = masterKey.derivedKeys[derivationPath] else {
            return nil
        }

        guard let seedKey = masterKey.publicKey else {
            throw KeysProviderError.masterKeyNotFound
        }

        return try JointAccountDerivationUtils.makeDerivedKey(
            seedKey: seedKey,
            derivationPath: derivationPath,
            extendedPublicKey: extendedPublicKey
        )
    }

    func sign(
        digest: Data,
        with derivedKey: JointAccountDerivedKey,
        seedKey: Data,
        in context: MobileWalletContext
    ) throws -> Data {
        let dataToSign = SignData(
            derivationPath: derivedKey.publicKey.derivationPath,
            hashes: [digest],
            publicKey: derivedKey.publicKey.blockchainKey
        )

        let signatures = try mobileWalletSdk.sign(dataToSign: [dataToSign], seedKey: seedKey, context: context)

        guard let signature = signatures.first?.signature else {
            throw Error.signatureNotFound
        }

        let signatureInfo = SignatureInfo(
            signature: signature,
            publicKey: derivedKey.publicKey.blockchainKey,
            hash: digest
        )

        return try signatureInfo.unmarshal()
    }
}

// MARK: - Error

extension JointAccountMobileWalletDerivationInteractor {
    enum Error: String, LocalizedError {
        case keyNotDerived
        case signatureNotFound

        var errorDescription: String? {
            switch self {
            case .keyNotDerived: "The derived key is missing from the derivation result."
            case .signatureNotFound: "The signature is missing from the signing result."
            }
        }
    }
}
