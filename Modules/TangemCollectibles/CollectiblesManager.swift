//
//  CollectiblesManager.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import Foundation
public import Combine
import BlockchainSdk
public import TangemFoundation

/// The single owner of the vault state: the app's account model wraps it rather than keeping a copy to keep
/// in step. Built for every wallet the feature is enabled for, whether or not a vault exists —
/// `CollectiblesState` carries the pre-vault cases and onboarding is what walks out of them.
public final class CollectiblesManager {
    public let userWalletId: UserWalletId

    private let coldOwnerProvider: any CollectiblesColdOwnerProvider
    private let vaultReader: any CollectiblesVaultReader
    private let vaultUsdcReader: any CollectiblesVaultUsdcReader
    private let balanceUpdater: any CollectiblesBalanceUpdater
    private let sessionKeySigner: any CollectiblesSessionKeySigner
    private let coldKeyInteractorFactory: any CollectiblesColdKeyInteractorFactory
    private let presenceStore: any CollectiblesAccountPresenceStore
    private let transactionSender: CollectiblesColdKeyTransactionSender
    private let onboardingInteractor: CollectiblesOnboardingInteractor
    private let purchaseTransactionDispatcher: CollectiblesPurchaseTransactionDispatcher
    private let buybackTransactionDispatcher: CollectiblesBuybackTransactionDispatcher
    private let delayProvider: any PollDelayProvider

    private let stateSubject = CurrentValueSubject<CollectiblesState, Never>(.unresolved)
    private let vaultUsdcStateSubject = CurrentValueSubject<CollectiblesVaultUsdcState, Never>(.loading)
    private let lastVaultUsdcBalance = OSAllocatedUnfairLock<UInt64?>(initialState: nil)

    private let refreshProcessor = SingleTaskProcessor<Bool, Never>()
    private let purchaseSigningTasks = OSAllocatedUnfairLock<[String: Task<CollectiblesSignedPurchase, any Error>]>(
        initialState: [:]
    )

    public init(
        userWalletId: UserWalletId,
        coldOwnerProvider: any CollectiblesColdOwnerProvider,
        vaultReader: any CollectiblesVaultReader,
        vaultUsdcReader: any CollectiblesVaultUsdcReader,
        balanceUpdater: any CollectiblesBalanceUpdater,
        sessionKeySigner: any CollectiblesSessionKeySigner,
        coldKeyInteractorFactory: any CollectiblesColdKeyInteractorFactory,
        transactionSender: CollectiblesColdKeyTransactionSender,
        onboardingInteractor: CollectiblesOnboardingInteractor,
        purchaseTransactionDispatcher: CollectiblesPurchaseTransactionDispatcher,
        buybackTransactionDispatcher: CollectiblesBuybackTransactionDispatcher,
        presenceStore: any CollectiblesAccountPresenceStore,
        delayProvider: any PollDelayProvider = TaskSleepPollDelayProvider()
    ) {
        self.userWalletId = userWalletId
        self.coldOwnerProvider = coldOwnerProvider
        self.vaultReader = vaultReader
        self.vaultUsdcReader = vaultUsdcReader
        self.balanceUpdater = balanceUpdater
        self.sessionKeySigner = sessionKeySigner
        self.coldKeyInteractorFactory = coldKeyInteractorFactory
        self.transactionSender = transactionSender
        self.onboardingInteractor = onboardingInteractor
        self.purchaseTransactionDispatcher = purchaseTransactionDispatcher
        self.buybackTransactionDispatcher = buybackTransactionDispatcher
        self.presenceStore = presenceStore
        self.delayProvider = delayProvider

        runTask { [weak self] in
            await self?.refreshState()
        }
    }
}

// MARK: - Account state

public extension CollectiblesManager {
    var state: CollectiblesState {
        stateSubject.value
    }

    var statePublisher: AnyPublisher<CollectiblesState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var hasAccount: Bool {
        state.hasAccount(markedLocally: isMarkedLocally)
    }

    var hasAccountPublisher: AnyPublisher<Bool, Never> {
        stateSubject
            .map { [presenceStore, userWalletId] state in
                state.hasAccount(markedLocally: presenceStore.contains(userWalletId))
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    /// Concurrent callers await the same resolve rather than each starting their own — independent reads can
    /// land out of order and publish a stale vault snapshot last.
    func refreshState() async {
        let joinedSilentRound = await refresh(silent: false)
        guard joinedSilentRound else {
            return
        }

        await refresh(silent: false)
    }
}

// MARK: - Top-up

public extension CollectiblesManager {
    var vaultUsdcStatePublisher: AnyPublisher<CollectiblesVaultUsdcState, Never> {
        vaultUsdcStateSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func awaitDeposit() async {
        let baseline = lastVaultUsdcBalance.withLock { $0 } ?? 0

        let polling = PollingSequence(
            interval: Constants.depositPollInterval,
            request: { [weak self] in await self?.refresh(silent: true) },
            delayProvider: delayProvider
        )

        _ = await polling
            .prefix(Constants.depositPollAttempts)
            .first { _ in (lastVaultUsdcBalance.withLock { $0 } ?? 0) > baseline }
    }
}

// MARK: - CollectiblesOnboarder protocol conformance

extension CollectiblesManager: CollectiblesOnboarder {
    /// Walks the resolved state toward `.ready`, applying the one thing it is missing and resolving again —
    /// the loop the agreed onboarding flow is drawn as. Every step reads before it writes, so an interrupted
    /// run is resumed by calling this again rather than repaired.
    public func onboard() async throws {
        var performedSteps: Set<CollectiblesOnboardingInteractor.OnboardingStep> = []

        while true {
            let resolved = try await resolveState()
            update(state: resolved)

            if performedSteps.isEmpty, resolved != .coldOwnerNotDerived {
                CollectiblesLogger.debug("create account: -> Solana address of the key stored locally, derivation skipped")
            }

            guard let step = try onboardingInteractor.onboardingStep(for: resolved) else {
                let outcome = performedSteps.isEmpty ? "nothing to do" : "set up in this run"
                CollectiblesLogger.debug("create account: the account is ready to use, \(outcome)")
                await refreshBalance(for: resolved, silent: false)
                return
            }

            // A step can land and still resolve back to the state that asked for it — an RPC that has not
            // caught up with a transaction it already accepted. Repeating it would spend the tap twice.
            guard !performedSteps.contains(step) else {
                CollectiblesLogger.debug("create account: \(step.logName) landed, waiting for the chain to catch up")

                guard try await waitForState(until: { $0 != resolved }) else {
                    throw CollectiblesOnboardingError.stepDidNotAdvance(step)
                }

                continue
            }

            performedSteps.formUnion(try await onboardingInteractor.perform(step, resolveState: resolveState))
        }
    }
}

// MARK: - Purchase

public extension CollectiblesManager {
    var purchaseAddresses: CollectiblesPurchaseAddresses? {
        guard case .ready = state, let coldOwner = coldOwnerProvider.coldOwnerKey()?.blockchainKey else {
            return nil
        }

        let ownerAddress = coldOwner.base58EncodedString

        return CollectiblesPurchaseAddresses(player: ownerAddress, prizeRecipient: ownerAddress)
    }
}

// MARK: - Buyback

public extension CollectiblesManager {
    var buybackAddresses: CollectiblesBuybackAddresses? {
        guard case .ready(let vault) = state, let coldOwner = coldOwnerProvider.coldOwnerKey()?.blockchainKey else {
            return nil
        }

        return CollectiblesBuybackAddresses(owner: coldOwner.base58EncodedString, payoutRecipient: vault.vaultAddress)
    }
}

// MARK: - Session-key operations (no card tap)

public extension CollectiblesManager {
    func signPurchase(
        _ purchase: CollectiblesPackPurchase,
        confirmedPrice: CollectiblesConfirmedPrice
    ) async throws -> CollectiblesSignedPurchase {
        try purchaseTransactionDispatcher.validate(purchase, against: confirmedPrice)

        let signing = purchaseSigningTasks.withLock { tasks in
            if let task = tasks[purchase.memo] {
                return task
            }

            let task = Task<CollectiblesSignedPurchase, any Error> { [weak self] in
                guard let self else {
                    throw CancellationError()
                }

                return try await makeSignedPurchase(purchase)
            }

            tasks[purchase.memo] = task
            return task
        }

        let signedPurchase: CollectiblesSignedPurchase

        do {
            signedPurchase = try await signing.value
        } catch {
            purchaseSigningTasks.withLock { tasks in
                guard tasks[purchase.memo] == signing else {
                    return
                }

                tasks[purchase.memo] = nil
            }

            throw error
        }

        guard signedPurchase.amount == purchase.amount, signedPurchase.feeAmount == purchase.feeAmount else {
            throw PurchaseError.conflictingPurchase
        }

        return signedPurchase
    }

    func sendPurchase(_ signedPurchase: CollectiblesSignedPurchase) async throws(CollectiblesSendError) {
        try await purchaseTransactionDispatcher.send(signedPurchase)
    }

    /// Frees an occupied legacy buyback slot — rotation alone does not revoke an issued Metaplex delegate.
    internal func revokeBuyback() async throws {
        // [REDACTED_TODO_COMMENT]
        throw NotImplementedError()
    }
}

// MARK: - Cold-signed operations (one card tap each)

extension CollectiblesManager {
    /// Replaces `session_key` with a freshly generated key — the compromised-device exit, not the reinstall
    /// one. `onboard()` handles a vault naming a key this phone does not hold by pointing the chain at the key
    /// it does; this discards a key that is still on chain, so it needs the pending-then-promote slot and a
    /// deliberate user action. Never invoked automatically: two devices rotating on refresh would fight forever.
    func rotateSessionKey() async throws {
        // [REDACTED_TODO_COMMENT]
        throw NotImplementedError()
    }

    /// Both caps go together: the program checks `0 < per_spin_cap <= daily_cap` on the combined state, so
    /// changing one can fail against the value stored for the other.
    public func updateCaps(perSpinCap: UInt64, dailyCap: UInt64) async throws {
        let coldKey = try coldOwnerProvider.requiredColdOwnerKey()

        let program = try CollectiblesVaultProgram(programId: CollectiblesChainEnvironment.programId)

        let instruction = try program.updateVaultInstruction(
            coldOwner: coldKey.blockchainKey,
            sessionKey: nil,
            perSpinCap: perSpinCap,
            dailyCap: dailyCap
        )

        let signed = try await transactionSender.sign(
            [instruction],
            coldKey: coldKey,
            blockhash: try await transactionSender.fetchLatestBlockhash(),
            signer: coldKeyInteractorFactory.makeInteractor()
        )
        let signature = try await transactionSender.broadcast(signed)
        CollectiblesLogger.debug("Caps updated, transaction \(signature ?? "landed by an earlier attempt")")

        // Reads are finalized, so a resolve right after the write still answers with the replaced caps
        let applied = try await waitForState { state in
            guard let vault = state.vault else {
                return false
            }

            return vault.perSpinCap == perSpinCap && vault.dailyCap == dailyCap
        }

        if !applied {
            CollectiblesLogger.debug("Caps not visible yet, leaving them to the next refresh")
        }

        await refreshState()
    }

    public func signBuyback(
        _ preparedTransaction: Data,
        terms: CollectiblesBuybackTerms
    ) async throws -> CollectiblesSignedBuyback {
        try await buybackTransactionDispatcher.sign(preparedTransaction, terms: terms)
    }

    public func sendBuyback(_ signedBuyback: CollectiblesSignedBuyback) async throws(CollectiblesSendError) {
        try await buybackTransactionDispatcher.send(signedBuyback)
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
        guard let sessionKey = try? await sessionKeySigner.publicKey(), sessionKey == vault.sessionKey else {
            return .rekeyRequired(vault)
        }

        return .ready(vault)
    }

    @discardableResult
    func refresh(silent: Bool) async -> Bool {
        await refreshProcessor.execute { [weak self] in
            guard let self else {
                return silent
            }

            do {
                let state = try await resolveState()
                update(state: state)
                await refreshBalance(for: state, silent: silent)
            } catch {
                // A read that failed says nothing about the vault, so the last resolved state stands
                CollectiblesLogger.error("State resolve failed, keeping the last known state", error: error)

                if !silent {
                    publishFailure(error)
                }
            }

            return silent
        }
    }

    /// Only a state that names a vault has an account to read: without one there is nowhere for USDC to be,
    /// which is not the same answer as a balance of zero.
    func refreshBalance(for state: CollectiblesState, silent: Bool) async {
        guard state.isAccountVisible, let coldOwner = coldOwnerProvider.coldOwnerKey()?.blockchainKey else {
            vaultUsdcStateSubject.send(.missing)
            balanceUpdater.update(.unavailable)
            return
        }

        if !silent {
            balanceUpdater.update(.loading)

            if vaultUsdcStateSubject.value == .failed {
                vaultUsdcStateSubject.send(.loading)
            }
        }

        do {
            publish(try await vaultUsdcReader.usdcAccount(coldOwner: coldOwner))
        } catch {
            CollectiblesLogger.error("Vault balance read failed", error: error)

            if !silent {
                publishFailure(error)
            }
        }
    }

    func publishFailure(_ error: Error) {
        if vaultUsdcStateSubject.value == .loading {
            vaultUsdcStateSubject.send(.failed)
        }

        balanceUpdater.update(.failed(error))
    }

    func publish(_ info: CollectiblesVaultUsdcInfo) {
        if info.account == nil {
            CollectiblesLogger.warning("Vault USDC account is missing, top-up stays unavailable")
        }

        lastVaultUsdcBalance.withLock { $0 = info.balance }
        vaultUsdcStateSubject.send(info.account.map { CollectiblesVaultUsdcState.ready($0) } ?? .missing)
        balanceUpdater.update(.loaded(info.balance))
    }

    func update(state: CollectiblesState) {
        recordPresence(of: state)

        // Every emission re-triggers the accounts pipeline's CombineLatest — don't re-publish sameness
        guard state != stateSubject.value else {
            CollectiblesLogger.debug("State resolve finished, unchanged: \(state.logDescription)")
            return
        }

        CollectiblesLogger.debug("State resolved: \(state.logDescription), was: \(stateSubject.value.logDescription)")
        stateSubject.send(state)
    }

    func recordPresence(of state: CollectiblesState) {
        switch state.presenceRecord {
        case .exists:
            presenceStore.insert(userWalletId)
        case .absent:
            presenceStore.remove(userWalletId)
        case .unchanged:
            break
        }
    }

    var isMarkedLocally: Bool {
        presenceStore.contains(userWalletId)
    }

    /// A node serves the transaction it accepted before it serves the account that transaction created, so the
    /// read right after a write is as likely to be early as to be the truth. A failed read costs an attempt
    /// like an early one; only cancellation ends the wait before its answer.
    func waitForState(until isSatisfied: (CollectiblesState) -> Bool) async throws -> Bool {
        for _ in 0 ..< Constants.stateAdvanceAttempts {
            try await delayProvider.wait(for: Constants.stateAdvanceInterval)

            if let state = try? await resolveState(), isSatisfied(state) {
                return true
            }
        }

        return false
    }
}

// MARK: - Purchase signing

private extension CollectiblesManager {
    func makeSignedPurchase(_ purchase: CollectiblesPackPurchase) async throws -> CollectiblesSignedPurchase {
        let state = try await resolveState()
        update(state: state)

        guard case .ready(let vault) = state else {
            throw PurchaseError.vaultNotReady
        }

        return try await purchaseTransactionDispatcher.sign(purchase, vault: vault)
    }
}

// MARK: - Error

private extension CollectiblesManager {
    enum PurchaseError: Error {
        case vaultNotReady
        case conflictingPurchase
    }
}

// MARK: - Constants

private extension CollectiblesManager {
    enum Constants {
        static let stateAdvanceAttempts = 10
        static let stateAdvanceInterval: TimeInterval = 2
        static let depositPollAttempts = 18
        static let depositPollInterval: TimeInterval = 5
    }
}

// MARK: - State accessors

private extension CollectiblesState {
    var vault: CollectiblesVaultInfo? {
        switch self {
        case .ready(let vault), .rekeyRequired(let vault): vault
        case .unresolved, .notOnboarded, .coldOwnerNotDerived: nil
        }
    }

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
