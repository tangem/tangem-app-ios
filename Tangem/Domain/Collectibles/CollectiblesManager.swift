//
//  CollectiblesManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation
import TangemCollectibles

/// Manager and account model are one object, so the vault state has a single owner and no copy of it to
/// keep in step. Built for every wallet the feature is enabled for, whether or not a vault exists —
/// `CollectiblesState` carries the pre-vault cases and onboarding is what walks out of them.
final class CollectiblesManager {
    let id: CollectiblesAccountId

    private let coldOwnerProvider: any CollectiblesColdOwnerProvider
    private let vaultReader: any CollectiblesVaultReader
    private let configReader: any CollectiblesConfigReader
    private let vaultUsdcReader: any CollectiblesVaultUsdcReader
    private let balanceService: any CollectiblesBalanceService
    private let hotDelegateSigner: any CollectiblesHotDelegateSigner
    private let coldKeyInteractorFactory: CollectiblesColdKeyInteractorFactory
    private let serviceProvider: CollectiblesChainServiceProvider

    private let nameSubject: CurrentValueSubject<String, Never>
    private let stateSubject = CurrentValueSubject<CollectiblesState, Never>(.unresolved)

    private let refreshProcessor = SingleTaskProcessor<Void, Never>()

    init(
        id: CollectiblesAccountId,
        name: String,
        coldOwnerProvider: any CollectiblesColdOwnerProvider,
        vaultReader: any CollectiblesVaultReader,
        configReader: any CollectiblesConfigReader,
        vaultUsdcReader: any CollectiblesVaultUsdcReader,
        balanceService: any CollectiblesBalanceService,
        hotDelegateSigner: any CollectiblesHotDelegateSigner,
        coldKeyInteractorFactory: CollectiblesColdKeyInteractorFactory,
        serviceProvider: CollectiblesChainServiceProvider
    ) {
        self.id = id
        nameSubject = CurrentValueSubject(name)
        self.coldOwnerProvider = coldOwnerProvider
        self.vaultReader = vaultReader
        self.configReader = configReader
        self.vaultUsdcReader = vaultUsdcReader
        self.balanceService = balanceService
        self.hotDelegateSigner = hotDelegateSigner
        self.coldKeyInteractorFactory = coldKeyInteractorFactory
        self.serviceProvider = serviceProvider

        runTask { [weak self] in
            await self?.refreshState()
        }
    }
}

// MARK: - CollectiblesAccountModel protocol conformance

extension CollectiblesManager: CollectiblesAccountModel {
    var name: String {
        nameSubject.value
    }

    var didChangePublisher: AnyPublisher<Void, Never> {
        nameSubject
            .removeDuplicates()
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    var state: CollectiblesState {
        stateSubject.value
    }

    var statePublisher: AnyPublisher<CollectiblesState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var fiatTotalTokenBalanceProvider: TokenBalanceProvider {
        balanceService.fiatTotalTokenBalanceProvider
    }

    func update(name: String) {
        guard name != nameSubject.value else {
            return
        }

        nameSubject.send(name)
    }

    /// Concurrent callers await the same resolve rather than each starting their own — independent reads can
    /// land out of order and publish a stale vault snapshot last.
    func refreshState() async {
        await refreshProcessor.execute { [weak self] in
            guard let self else {
                return
            }

            do {
                let state = try await resolveState()
                update(state: state)
                await refreshBalance(for: state)
            } catch {
                // A read that failed says nothing about the vault, so the last resolved state stands
                CollectiblesLogger.error("State resolve failed, keeping the last known state", error: error)
            }
        }
    }
}

// MARK: - CollectiblesOnboarder protocol conformance

extension CollectiblesManager: CollectiblesOnboarder {
    /// Walks the resolved state toward `.ready`, applying the one thing it is missing and resolving again —
    /// the loop the agreed onboarding flow is drawn as. Every step reads before it writes, so an interrupted
    /// run is resumed by calling this again rather than repaired.
    func onboard() async throws {
        var performedSteps: Set<OnboardingStep> = []

        while true {
            let resolved = try await resolveState()
            update(state: resolved)

            let step: OnboardingStep

            switch resolved {
            case .ready:
                await refreshBalance(for: resolved)
                return
            case .coldOwnerNotDerived:
                step = .deriveColdKey
            // [REDACTED_TODO_COMMENT]
            // is one whose cold owner address came into existence a step ago and holds nothing, so the deploy
            // it needs to pay for cannot succeed yet. Stop for the tester to fund the address just logged.
            // Recovery is not caught here: a vault already on chain means the same deterministic address was
            // funded before, and its balance outlived the install that derived it.
            case .notOnboarded where performedSteps.contains(.deriveColdKey):
                throw OnboardingError.coldOwnerNeedsFunding
            case .notOnboarded:
                step = .deployVault
            case .rekeyRequired:
                step = .pointVaultAtHeldDelegate
            case .unresolved:
                // `resolveState` answers with a resolved case or throws; this is only ever the value
                // published before the first resolve finishes
                throw OnboardingError.stateUnresolved
            }

            // A step can land and still resolve back to the state that asked for it — an RPC that has not
            // caught up with a transaction it already accepted. Repeating it would spend the tap twice.
            guard performedSteps.insert(step).inserted else {
                guard try await waitForState(toAdvanceFrom: resolved) else {
                    throw OnboardingError.stepDidNotAdvance(step)
                }

                continue
            }

            try await perform(step)
        }
    }
}

// MARK: - Hot-signed operations (no card tap)

extension CollectiblesManager {
    /// Spin: signs sponsor-assembled `open_pack` bytes. Verification precedes signing inside this manager,
    /// so unverified backend bytes can never reach the key.
    func openPack(preparedTransaction: Data) async throws {
        // [REDACTED_TODO_COMMENT]
        throw NotImplementedError()
    }

    /// Countersigns a buyback transaction assembled by Collector Crypt.
    func countersignBuyback(preparedTransaction: Data) async throws {
        // [REDACTED_TODO_COMMENT]
        throw NotImplementedError()
    }

    /// Frees an occupied legacy buyback slot — rotation alone does not revoke an issued Metaplex delegate.
    func revokeBuyback() async throws {
        // [REDACTED_TODO_COMMENT]
        throw NotImplementedError()
    }
}

// MARK: - Cold-signed operations (one card tap each)

extension CollectiblesManager {
    /// Replaces `hot_delegate` with a freshly generated key — the compromised-device exit, not the reinstall
    /// one. `onboard()` handles a vault naming a key this phone does not hold by pointing the chain at the key
    /// it does; this discards a key that is still on chain, so it needs the pending-then-promote slot and a
    /// deliberate user action. Never invoked automatically: two devices rotating on refresh would fight forever.
    func rotateHotDelegate() async throws {
        // [REDACTED_TODO_COMMENT]
        throw NotImplementedError()
    }

    /// Both caps are always sent together: the program checks `0 < per_spin_cap <= daily_cap` on the
    /// combined state, so a single-cap change can fail against the stored value of the other.
    func updateCaps(perSpinCap: UInt64, dailyCap: UInt64) async throws {
        // [REDACTED_TODO_COMMENT]
        throw NotImplementedError()
    }

    func withdrawToken(amount: UInt64, destination: String) async throws {
        // [REDACTED_TODO_COMMENT]
        throw NotImplementedError()
    }

    /// Withdraws a prize; pNFT and Core assets take different instructions under one seam.
    func withdrawPrize(mint: String, destination: String) async throws {
        // [REDACTED_TODO_COMMENT]
        throw NotImplementedError()
    }

    /// Recovers stray SOL from the vault PDA — the vault never holds SOL by design.
    func withdrawSOL(lamports: UInt64, destination: String) async throws {
        // [REDACTED_TODO_COMMENT]
        throw NotImplementedError()
    }

    /// Offboarding, in order: free the buyback slot → withdraw everything → close token accounts → `close_vault`.
    func closeVault() async throws {
        // [REDACTED_TODO_COMMENT]
        // fee-payer nondeterminism and sends the rent to the cold key. Android bundles the token-account close with
        // `close_vault` and omits it when the account is already gone, so an interrupted offboarding cannot leave a
        // vault without the account it receives USDC on — match that shape.
        throw NotImplementedError()
    }
}

// MARK: - State resolution

private extension CollectiblesManager {
    /// The single place the three questions are asked, so onboarding decides on the same answer the account
    /// list shows. Reads the chain and this device only — when the account gains a backend record it joins
    /// here as the fast path and neither the loop nor its steps have to change.
    func resolveState() async throws -> CollectiblesState {
        CollectiblesLogger.debug("State resolve started, current: \(stateSubject.value.logDescription)")

        guard let coldOwner = coldOwnerProvider.coldOwnerKey()?.blockchainKey else {
            return .coldOwnerNotDerived
        }

        guard let vault = try await vaultReader.vaultInfo(coldOwner: coldOwner) else {
            return .notOnboarded
        }

        // A local key that cannot be read counts as a mismatch: either way this device cannot sign for the vault
        guard let hotDelegate = try? await hotDelegateSigner.publicKey(), hotDelegate == vault.hotDelegate else {
            return .rekeyRequired(vault)
        }

        return .ready(vault)
    }

    /// Only a state that names a vault has an account to read: without one there is nowhere for USDC to be,
    /// which is not the same answer as a balance of zero.
    func refreshBalance(for state: CollectiblesState) async {
        guard state.isAccountVisible, let coldOwner = coldOwnerProvider.coldOwnerKey()?.blockchainKey else {
            balanceService.update(.unavailable)
            return
        }

        balanceService.update(.loading)

        do {
            let balance = try await vaultUsdcReader.usdcBalance(coldOwner: coldOwner)
            balanceService.update(.loaded(balance))
        } catch {
            CollectiblesLogger.error("Vault balance read failed", error: error)
            balanceService.update(.failed(error))
        }
    }

    func update(state: CollectiblesState) {
        // Every emission re-triggers the accounts pipeline's CombineLatest — don't re-publish sameness
        guard state != stateSubject.value else {
            CollectiblesLogger.debug("State resolve finished, unchanged: \(state.logDescription)")
            return
        }

        CollectiblesLogger.debug("State resolved: \(state.logDescription), was: \(stateSubject.value.logDescription)")
        stateSubject.send(state)
    }
}

// MARK: - Onboarding steps

private extension CollectiblesManager {
    enum OnboardingStep: Hashable {
        case deriveColdKey
        case deployVault
        case pointVaultAtHeldDelegate
    }

    func perform(_ step: OnboardingStep) async throws {
        switch step {
        case .deriveColdKey:
            try await deriveColdKey()
        case .deployVault:
            try await deployVault()
        case .pointVaultAtHeldDelegate:
            try await pointVaultAtHeldDelegate()
        }
    }

    /// The head of the chain: until this key exists nothing else has an address.
    func deriveColdKey() async throws {
        try await coldKeyInteractorFactory.makeInteractor().derive()

        // [REDACTED_TODO_COMMENT]
        if let coldOwner = coldOwnerProvider.coldOwnerKey()?.blockchainKey {
            CollectiblesLogger.debug("Cold owner derived (top up with devnet SOL): \(coldOwner.base58EncodedString)")
        }
    }

    /// Generates only when there is no key to read — one this device cannot open cannot sign for the vault
    /// either, and the caller names whatever comes back on chain within the same run. Discarding a key that
    /// still works is a different act, and `rotateHotDelegate()` owns it.
    func ensureHotDelegate() async throws -> Data {
        if let hotDelegate = try await hotDelegateSigner.publicKey() {
            return hotDelegate
        }

        return try await hotDelegateSigner.generateKey()
    }

    /// The only thing that ever creates the account the vault receives USDC on. One transaction carries both,
    /// so they either both exist or neither does — Android deploys the same bundle, which is why nothing
    /// re-checks the pairing. The vault is initialized with the delegate this phone holds, so no rotation
    /// follows.
    func deployVault() async throws {
        let coldKey = try coldKey()
        let coldOwner = coldKey.blockchainKey
        let hotDelegate = try await ensureHotDelegate()

        let program = try CollectiblesVaultProgram(programId: CollectiblesChainEnvironment.programId)
        let usdcMint = try await configReader.configInfo().usdcMint

        let vaultAddress = try program.vaultAddress(coldOwner: coldOwner)
        let vaultUsdcAddress = try program.vaultUsdcAddress(coldOwner: coldOwner, usdcMint: usdcMint)
        CollectiblesLogger.debug("Cold owner (top up with devnet SOL): \(coldOwner.base58EncodedString)")
        CollectiblesLogger.debug("Vault address: \(vaultAddress)")
        CollectiblesLogger.debug("Vault USDC address: \(vaultUsdcAddress)")

        let initVault = try program.initVaultInstruction(
            coldOwner: coldOwner,
            payer: coldOwner,
            hotDelegate: hotDelegate,
            perSpinCap: CollectiblesChainEnvironment.initialPerSpinCap,
            dailyCap: CollectiblesChainEnvironment.initialDailyCap
        )

        let createVaultUsdc = try program.createVaultUsdcInstruction(
            payer: coldOwner,
            coldOwner: coldOwner,
            usdcMint: usdcMint
        )

        let signature = try await broadcast(coldKey: coldKey, instructions: [initVault, createVaultUsdc])
        CollectiblesLogger.debug("Vault deployed, transaction \(signature ?? Constants.landedEarlier)")
    }

    /// The reinstall exit: the vault outlives the local delegate, so a vault naming a different key gets
    /// `update_vault` pointing it back at the key this phone already holds, leaving both caps as the chain
    /// holds them. Nothing local is generated or discarded — the chain is what moves.
    func pointVaultAtHeldDelegate() async throws {
        let coldKey = try coldKey()
        let hotDelegate = try await ensureHotDelegate()

        let program = try CollectiblesVaultProgram(programId: CollectiblesChainEnvironment.programId)

        let instruction = try program.updateVaultInstruction(
            coldOwner: coldKey.blockchainKey,
            hotDelegate: hotDelegate,
            perSpinCap: nil,
            dailyCap: nil
        )

        let signature = try await broadcast(coldKey: coldKey, instructions: [instruction])
        CollectiblesLogger.debug("Hot delegate rotated, transaction \(signature ?? Constants.landedEarlier)")
    }

    /// A node serves the transaction it accepted before it serves the account that transaction created, so the
    /// read right after a step is as likely to be early as to be the truth. Re-reads until the state moves.
    func waitForState(toAdvanceFrom state: CollectiblesState) async throws -> Bool {
        for _ in 0 ..< Constants.stateAdvanceAttempts {
            try await Task.sleep(for: Constants.stateAdvanceInterval)

            if try await resolveState() != state {
                return true
            }
        }

        return false
    }

    func coldKey() throws -> Wallet.PublicKey {
        guard let coldKey = coldOwnerProvider.coldOwnerKey() else {
            throw OnboardingError.coldKeyNotDerived
        }

        return coldKey
    }

    // [REDACTED_TODO_COMMENT]
    /// `nil` when the node already held the transaction: an earlier attempt reached the chain and only its
    /// response was lost. Nothing here has to tell "seen before" apart from "applied" — the loop resolves
    /// again after every step, and a change that never landed shows up as a state that did not advance.
    func broadcast(coldKey: Wallet.PublicKey, instructions: [CollectiblesInstruction]) async throws -> String? {
        do {
            return try await serviceProvider.service().sendSelfPaid(
                instructions: instructions.map(Self.rawInstruction),
                feePayer: coldKey.blockchainKey
            ) { message in
                try await coldKeyInteractorFactory.makeInteractor().sign(message: message, coldKey: coldKey)
            }
        } catch SolanaSponsoredTransactionService.SendError.alreadyProcessed {
            return nil
        }
    }

    static func rawInstruction(_ instruction: CollectiblesInstruction) -> SolanaRawInstruction {
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

private extension CollectiblesManager {
    enum OnboardingError: Error {
        case coldKeyNotDerived
        case coldOwnerNeedsFunding
        case stateUnresolved
        case stepDidNotAdvance(OnboardingStep)
    }

    enum Constants {
        static let landedEarlier = "landed by an earlier attempt"
        static let stateAdvanceAttempts = 5
        static let stateAdvanceInterval: Duration = .seconds(2)
    }
}

// MARK: - Log description

private extension CollectiblesState {
    /// Debug-only: the vault address and the remaining daily budget are per-user spend data, so they stay
    /// out of the production log file rather than being written at a level the sanitizer lets through.
    var logDescription: String {
        switch self {
        case .unresolved: "unresolved"
        case .notOnboarded: "notOnboarded"
        case .coldOwnerNotDerived: "coldOwnerNotDerived"
        case .rekeyRequired(let vault): "rekeyRequired(vault: \(vault.vaultAddress))"
        case .ready(let vault): "ready(vault: \(vault.vaultAddress), remainingToday: \(vault.remainingToday(now: Date())))"
        }
    }
}

/// Keeps the unimplemented operations inert: a caller gets a throw, never a silent success.
private struct NotImplementedError: Error {}
