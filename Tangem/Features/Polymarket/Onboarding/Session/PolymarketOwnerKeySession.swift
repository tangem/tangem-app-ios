//
//  PolymarketOwnerKeySession.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemPolymarket

protocol PolymarketOwnerKeySession {
    func derive<Output>(
        andRun work: @escaping (PolymarketOwnerKeySessionContext) async throws -> Output
    ) async throws -> Output
}

protocol PolymarketOwnerKeySessionProvider: AnyObject {
    var polymarketOwnerKeySession: PolymarketOwnerKeySession { get }
}

struct PolymarketOwnerKeySessionContext {
    let ownerAddress: String
    let signer: PolymarketOnboardingSigning
}

extension PolymarketOwnerKeySessionContext {
    init(
        ownerKey: Wallet.PublicKey,
        keysRepository: KeysRepository,
        signer: PolymarketOwnerKeySigner
    ) throws(PolymarketOnboardingError) {
        do {
            ownerAddress = try PolymarketUtilities.makeAddress(using: ownerKey)
        } catch {
            PolymarketLogger.error("Failed to make the owner address", error: error)
            throw .derivation(.addressCreationFailed)
        }

        self.signer = CommonPolymarketOnboardingSigner(keysRepository: keysRepository, signer: signer)
    }
}

// MARK: - Preflight

extension PolymarketUtilities {
    static func sessionSeedKey(
        from keysRepository: KeysRepository,
        config: UserWalletConfig
    ) throws(PolymarketOnboardingError) -> Data {
        guard
            let masterKey = try? keysRepository.masterKey(curve: mandatoryCurve),
            let seedKey = masterKey.publicKey
        else {
            throw .derivation(.missingWallet)
        }

        guard config.hasFeature(.hdWallets) else {
            throw .derivation(.derivationUnsupported)
        }

        return seedKey
    }
}

// MARK: - Unavailable

struct UnavailablePolymarketOwnerKeySession: PolymarketOwnerKeySession {
    func derive<Output>(
        andRun work: @escaping (PolymarketOwnerKeySessionContext) async throws -> Output
    ) async throws -> Output {
        throw PolymarketOnboardingError.derivation(.missingWallet)
    }
}
