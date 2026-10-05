//
//  CollectiblesOnboardingInteractor.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

public struct CollectiblesOnboardingInteractor {
    // MARK: - Properties

    private let coldOwnerProvider: any CollectiblesColdOwnerProvider
    private let sessionKeySigner: any CollectiblesSessionKeySigner
    private let configReader: any CollectiblesConfigReader
    private let coldKeyInteractorFactory: any CollectiblesColdKeyInteractorFactory
    private let transactionSender: CollectiblesColdKeyTransactionSender

    // MARK: - Init

    public init(
        coldOwnerProvider: any CollectiblesColdOwnerProvider,
        sessionKeySigner: any CollectiblesSessionKeySigner,
        configReader: any CollectiblesConfigReader,
        coldKeyInteractorFactory: any CollectiblesColdKeyInteractorFactory,
        transactionSender: CollectiblesColdKeyTransactionSender
    ) {
        self.coldOwnerProvider = coldOwnerProvider
        self.sessionKeySigner = sessionKeySigner
        self.configReader = configReader
        self.coldKeyInteractorFactory = coldKeyInteractorFactory
        self.transactionSender = transactionSender
    }
}

// MARK: - Steps

extension CollectiblesOnboardingInteractor {
    enum OnboardingStep: Hashable {
        case deriveColdKeyAndSetUpVault
        case vault(VaultStep)

        var logName: String {
            switch self {
            case .deriveColdKeyAndSetUpVault: "derivation"
            case .vault(let step): step.instructionName
            }
        }
    }

    enum VaultStep: Hashable {
        case deploy
        /// Points a vault that names an unknown session key back at the one this phone holds — the exit from a
        /// reinstall. Caps stay as the chain holds them.
        case pointAtHeldSessionKey

        var instructionName: String {
            switch self {
            case .deploy: "init_vault"
            case .pointAtHeldSessionKey: "update_vault"
            }
        }
    }

    func onboardingStep(for state: CollectiblesState) throws -> OnboardingStep? {
        switch state {
        case .ready: nil
        case .coldOwnerNotDerived: .deriveColdKeyAndSetUpVault
        case .notOnboarded: .vault(.deploy)
        case .rekeyRequired: .vault(.pointAtHeldSessionKey)
        // `resolveState` answers with a resolved case or throws; this is only ever the value
        // published before the first resolve finishes
        case .unresolved: throw CollectiblesOnboardingError.stateUnresolved
        }
    }

    func perform(
        _ step: OnboardingStep,
        resolveState: @escaping () async throws -> CollectiblesState
    ) async throws -> Set<OnboardingStep> {
        switch step {
        case .deriveColdKeyAndSetUpVault:
            guard let vaultStep = try await deriveColdKeyAndSetUpVault(resolveState: resolveState) else {
                return [step]
            }

            return [step, .vault(vaultStep)]
        case .vault(let vaultStep):
            let inputs = try await vaultSetUpInputs()
            let signer = coldKeyInteractorFactory.makeInteractor()
            let signedStep = try await signVaultStep(vaultStep, signer: signer, inputs: inputs)
            try await sendVaultTransaction(signedStep)
            return [step]
        }
    }
}

// MARK: - Private logic

private extension CollectiblesOnboardingInteractor {
    struct VaultSetUpInputs {
        let sessionKey: Data
        let usdcMint: Data
        let blockhash: SolanaBlockhash
    }

    struct SignedVaultStep {
        let step: VaultStep
        let vaultAddress: String
        let signed: CollectiblesColdKeyTransactionSender.SignedTransaction
    }

    /// The head of the chain: until this key exists nothing else has an address.
    func deriveColdKeyAndSetUpVault(
        resolveState: @escaping () async throws -> CollectiblesState
    ) async throws -> VaultStep? {
        CollectiblesLogger.debug("create account: -> No locally stored Solana address, deriving it")
        let work = VaultSetUpWork(interactor: self, inputs: try await vaultSetUpInputs(), resolveState: resolveState)
        let signedStep: SignedVaultStep?

        do {
            signedStep = try await coldKeyInteractorFactory.makeInteractor().derive(andRun: work)
        } catch {
            CollectiblesLogger.debug("create account: the one-tap set-up failed: \(error)")
            throw error
        }

        guard let signedStep else {
            return nil
        }

        try await sendVaultTransaction(signedStep)
        return signedStep.step
    }

    func vaultSetUpInputs() async throws -> VaultSetUpInputs {
        VaultSetUpInputs(
            sessionKey: try await ensureSessionKey(),
            usdcMint: try await configReader.configInfo().usdcMint,
            blockhash: try await transactionSender.fetchLatestBlockhash()
        )
    }

    /// Generates only when there is none to read; discarding a key that still works belongs to
    /// `rotateSessionKey()`.
    func ensureSessionKey() async throws -> Data {
        let storedSessionKey: Data?

        do {
            storedSessionKey = try await sessionKeySigner.publicKey()
        } catch {
            CollectiblesLogger.debug("hotDelegate: reading the stored hot session key failed, error=\(error)")
            throw error
        }

        if let storedSessionKey {
            CollectiblesLogger.debug("hotDelegate: is a hot session key stored on the phone -> Yes, reusing it")
            return storedSessionKey
        }

        CollectiblesLogger.debug("hotDelegate: is a hot session key stored on the phone -> No, generating one")

        do {
            let sessionKey = try await sessionKeySigner.generateKey()
            CollectiblesLogger.debug("hotDelegate: hot session key generated")
            return sessionKey
        } catch {
            CollectiblesLogger.debug("hotDelegate: provision failed, error=\(error)")
            throw error
        }
    }

    func signVaultStep(
        _ step: VaultStep,
        signer: any CollectiblesColdKeySigner,
        inputs: VaultSetUpInputs
    ) async throws -> SignedVaultStep {
        switch step {
        case .deploy:
            CollectiblesLogger.debug("vault: does the User Account PDA exist on chain? -> No, creating the User Account PDA (init_vault)")
        case .pointAtHeldSessionKey:
            CollectiblesLogger.debug("vault: is the hot key the same as in the User Account PDA? -> No or unreadable on the phone, updating the key in the PDA (update_vault)")
        }

        do {
            let coldKey = try coldOwnerProvider.requiredColdOwnerKey()
            let program = try CollectiblesVaultProgram(programId: CollectiblesChainEnvironment.programId)
            let instructions = try vaultInstructions(
                for: step,
                program: program,
                coldOwner: coldKey.blockchainKey,
                inputs: inputs
            )
            let signed = try await transactionSender.sign(
                instructions,
                coldKey: coldKey,
                blockhash: inputs.blockhash,
                signer: signer
            )

            return SignedVaultStep(
                step: step,
                vaultAddress: try program.vaultAddress(coldOwner: coldKey.blockchainKey),
                signed: signed
            )
        } catch {
            CollectiblesLogger.debug("vault: \(step.instructionName) failed: \(error)")
            throw error
        }
    }

    func vaultInstructions(
        for step: VaultStep,
        program: CollectiblesVaultProgram,
        coldOwner: Data,
        inputs: VaultSetUpInputs
    ) throws -> [CollectiblesInstruction] {
        switch step {
        case .deploy:
            return try deployVaultInstructions(program: program, coldOwner: coldOwner, inputs: inputs)
        case .pointAtHeldSessionKey:
            return [
                try program.updateVaultInstruction(
                    coldOwner: coldOwner,
                    sessionKey: inputs.sessionKey,
                    perSpinCap: nil,
                    dailyCap: nil
                ),
            ]
        }
    }

    /// One transaction carries the vault and the account it receives USDC on, so they either both exist or
    /// neither does.
    func deployVaultInstructions(
        program: CollectiblesVaultProgram,
        coldOwner: Data,
        inputs: VaultSetUpInputs
    ) throws -> [CollectiblesInstruction] {
        let vaultAddress = try program.vaultAddress(coldOwner: coldOwner)
        let vaultUsdcAddress = try program.vaultUsdcAddress(coldOwner: coldOwner, usdcMint: inputs.usdcMint)
        CollectiblesLogger.debug("Cold owner (top up with devnet SOL): \(coldOwner.base58EncodedString)")
        CollectiblesLogger.debug("Vault address: \(vaultAddress)")
        CollectiblesLogger.debug("Vault USDC address: \(vaultUsdcAddress)")

        let initVault = try program.initVaultInstruction(
            coldOwner: coldOwner,
            payer: coldOwner,
            sessionKey: inputs.sessionKey,
            perSpinCap: CollectiblesChainEnvironment.initialPerSpinCap,
            dailyCap: CollectiblesChainEnvironment.initialDailyCap
        )

        let createVaultUsdc = try program.createVaultUsdcInstruction(
            payer: coldOwner,
            coldOwner: coldOwner,
            usdcMint: inputs.usdcMint
        )

        return [initVault, createVaultUsdc]
    }

    func sendVaultTransaction(_ signedStep: SignedVaultStep) async throws {
        let instructionName = signedStep.step.instructionName
        let signature: String?

        do {
            signature = try await transactionSender.broadcast(signedStep.signed)
        } catch {
            CollectiblesLogger.debug("vault: \(instructionName) failed: \(error)")
            throw error
        }

        let sentSignature = signature ?? "landed by an earlier attempt"
        CollectiblesLogger.debug("vault: \(instructionName) sent, PDA=\(signedStep.vaultAddress), signature=\(sentSignature)")
    }
}

// MARK: - In-session vault set-up

private struct VaultSetUpWork: CollectiblesColdKeySessionWork {
    let interactor: CollectiblesOnboardingInteractor
    let inputs: CollectiblesOnboardingInteractor.VaultSetUpInputs
    let resolveState: () async throws -> CollectiblesState

    func run(signer: any CollectiblesColdKeySigner) async throws -> CollectiblesOnboardingInteractor.SignedVaultStep? {
        CollectiblesLogger.debug("ownerDeriver: Solana address was derived and saved")

        let state = try await resolveState()

        switch try interactor.onboardingStep(for: state) {
        case .none:
            return nil
        case .vault(let vaultStep):
            return try await interactor.signVaultStep(vaultStep, signer: signer, inputs: inputs)
        case .deriveColdKeyAndSetUpVault:
            throw CollectiblesOnboardingError.coldKeyNotDerived
        }
    }
}
