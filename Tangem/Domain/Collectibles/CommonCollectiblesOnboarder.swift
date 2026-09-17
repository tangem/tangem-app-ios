//
//  CommonCollectiblesOnboarder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemCollectibles
import TangemFoundation

// [REDACTED_TODO_COMMENT]
// folds derivation and signing into a single NFC session
/// The vault deployment ceremony against devnet: the cold key pays its own fee and rent, so the derived
/// address must be topped up with SOL first — it is logged on every attempt for exactly that.
final class CommonCollectiblesOnboarder {
    private let userWalletModel: any UserWalletModel
    private let coldOwnerProvider: any CollectiblesColdOwnerProvider
    private let vaultReader: any CollectiblesVaultReader
    private let hotDelegateSigner: any CollectiblesHotDelegateSigner
    private let serviceProvider: CollectiblesChainServiceProvider

    init(
        userWalletModel: any UserWalletModel,
        coldOwnerProvider: (any CollectiblesColdOwnerProvider)? = nil,
        vaultReader: (any CollectiblesVaultReader)? = nil,
        hotDelegateSigner: (any CollectiblesHotDelegateSigner)? = nil,
        serviceProvider: CollectiblesChainServiceProvider = CollectiblesChainServiceProvider()
    ) {
        self.userWalletModel = userWalletModel
        self.serviceProvider = serviceProvider
        self.coldOwnerProvider = coldOwnerProvider ?? CommonCollectiblesColdOwnerProvider(
            keysRepository: userWalletModel.keysRepository,
            config: userWalletModel.config
        )
        self.vaultReader = vaultReader ?? CommonCollectiblesChainReader(serviceProvider: serviceProvider)
        self.hotDelegateSigner = hotDelegateSigner ?? CommonCollectiblesHotDelegateSigner(userWalletId: userWalletModel.userWalletId)
    }
}

// MARK: - CollectiblesOnboarder protocol conformance

extension CommonCollectiblesOnboarder: CollectiblesOnboarder {
    func onboard() async throws {
        let coldKey = try await deriveColdKeyIfNeeded()
        let coldOwner = coldKey.blockchainKey

        let program = try CollectiblesVaultProgram(programId: CollectiblesChainEnvironment.programId)
        let vaultAddress = try program.vaultAddress(coldOwner: coldOwner)
        CollectiblesLogger.debug("Cold owner (top up with devnet SOL): \(coldOwner.base58EncodedString)")
        CollectiblesLogger.debug("Vault address: \(vaultAddress)")

        if try await vaultReader.vaultInfo(coldOwner: coldOwner) != nil {
            return
        }

        let hotDelegate = try await ensureHotDelegate()

        let instruction = try program.initVaultInstruction(
            coldOwner: coldOwner,
            payer: coldOwner,
            hotDelegate: hotDelegate,
            perSpinCap: CollectiblesChainEnvironment.initialPerSpinCap,
            dailyCap: CollectiblesChainEnvironment.initialDailyCap
        )

        let chainService = try serviceProvider.service()

        let signature = try await broadcast(coldOwner: coldOwner) {
            try await chainService.sendSelfPaid(
                instructions: [makeRawInstruction(instruction)],
                feePayer: coldKey,
                signer: userWalletModel.signer
            )
        }
        CollectiblesLogger.debug("Vault deployed, transaction \(signature ?? Constants.landedEarlier)")
    }
}

// MARK: - Private implementation

private extension CommonCollectiblesOnboarder {
    /// `nil` when the node already held the transaction: an earlier attempt reached the chain and only its
    /// response was lost. `alreadyProcessed` only means the node has seen that signature before, not that
    /// it landed — so a vault read confirms the deploy actually happened before this counts as done, rather
    /// than reporting success for an attempt that failed on-chain.
    func broadcast(coldOwner: Data, _ send: () async throws -> String) async throws -> String? {
        do {
            return try await send()
        } catch SolanaSponsoredTransactionService.SendError.alreadyProcessed {
            guard try await vaultReader.vaultInfo(coldOwner: coldOwner) != nil else {
                throw OnboardingError.deployNotConfirmed
            }

            return nil
        }
    }

    func deriveColdKeyIfNeeded() async throws -> Wallet.PublicKey {
        if let coldKey = coldOwnerProvider.coldOwnerKey() {
            return coldKey
        }

        let seedKey = try userWalletModel.keysRepository.masterKeyPublicKey(
            curve: CollectiblesAccountKeyPath.curve(for: userWalletModel.config)
        )

        let derivations = try await userWalletModel.keysDerivingInteractor.deriveKeys(
            derivations: [seedKey: [CollectiblesAccountKeyPath.derivationPath]]
        )
        userWalletModel.keysRepository.update(derivations: derivations)

        guard let coldKey = coldOwnerProvider.coldOwnerKey() else {
            throw OnboardingError.coldKeyNotDerived
        }

        return coldKey
    }

    func ensureHotDelegate() async throws -> Data {
        if let hotDelegate = try await hotDelegateSigner.publicKey() {
            return hotDelegate
        }

        return try await hotDelegateSigner.generateKey()
    }

    func makeRawInstruction(_ instruction: CollectiblesInstruction) -> SolanaRawInstruction {
        SolanaRawInstruction(
            programId: instruction.programId,
            accounts: instruction.accounts.map {
                .init(address: $0.address, isSigner: $0.isSigner, isWritable: $0.isWritable)
            },
            data: instruction.data
        )
    }
}

// MARK: - Error

private extension CommonCollectiblesOnboarder {
    enum OnboardingError: Error {
        case coldKeyNotDerived
        case deployNotConfirmed
    }

    enum Constants {
        static let landedEarlier = "landed by an earlier attempt"
    }
}
