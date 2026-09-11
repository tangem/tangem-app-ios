//
//  CollectiblesManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemCollectibles

/// Manager and account model are one object, so the vault state has a single owner and no copy of it
/// to keep in step.
final class CollectiblesManager {
    let id: CollectiblesAccountId

    private let coldOwnerProvider: any CollectiblesColdOwnerProvider
    private let vaultReader: any CollectiblesVaultReader
    private let hotDelegateSigner: CollectiblesHotDelegateSigner

    private let nameSubject: CurrentValueSubject<String, Never>
    private let stateSubject = CurrentValueSubject<CollectiblesState, Never>(.unresolved)
    private let refreshTaskSlot = OSAllocatedUnfairLock<Task<Void, any Error>?>(initialState: nil)

    init(
        id: CollectiblesAccountId,
        name: String,
        coldOwnerProvider: any CollectiblesColdOwnerProvider,
        vaultReader: any CollectiblesVaultReader,
        hotDelegateSigner: CollectiblesHotDelegateSigner
    ) {
        self.id = id
        nameSubject = CurrentValueSubject(name)
        self.coldOwnerProvider = coldOwnerProvider
        self.vaultReader = vaultReader
        self.hotDelegateSigner = hotDelegateSigner
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

    func update(name: String) {
        guard name != nameSubject.value else {
            return
        }

        nameSubject.send(name)
    }
}

// MARK: - State resolution

extension CollectiblesManager {
    func refreshState() async {
        // A read that failed says nothing about the vault, so the last resolved state stands
        try? await sharedRefreshTask().value
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
    /// Onboarding ceremony: derive the cold key and `init_vault` in one NFC session. Must re-resolve between
    /// the two — a vault may already exist for this seed, and then it is a re-key, not a create.
    func onboard() async throws {
        // [REDACTED_TODO_COMMENT]
        throw NotImplementedError()
    }

    /// Rotates `hot_delegate` to a fresh local key — the `rekeyRequired` exit. Never invoked automatically:
    /// two devices auto-re-keying on refresh would fight forever, burning taps.
    func rekey() async throws {
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
        // fee-payer nondeterminism and sends the rent to the cold key
        throw NotImplementedError()
    }
}

// MARK: - Private implementation

private extension CollectiblesManager {
    /// Concurrent callers join the in-flight resolve — independent reads can land out of order
    /// and publish a stale vault snapshot last.
    func sharedRefreshTask() -> Task<Void, any Error> {
        refreshTaskSlot.withLock { slot in
            if let task = slot {
                return task
            }

            let task = Task { [weak self] in
                defer { self?.refreshTaskSlot.withLock { $0 = nil } }
                try await self?.resolveAndPublishState()
            }

            slot = task
            return task
        }
    }

    func resolveAndPublishState() async throws {
        guard let coldOwner = coldOwnerProvider.coldOwnerKey()?.blockchainKey else {
            update(state: .coldOwnerNotDerived)
            return
        }

        guard let vault = try await vaultReader.vaultInfo(coldOwner: coldOwner) else {
            update(state: .notOnboarded)
            return
        }

        update(state: await reconcile(vault: vault))
    }

    func reconcile(vault: CollectiblesVaultInfo) async -> CollectiblesState {
        // A local key that cannot be read counts as a mismatch: either way this device cannot sign for the vault
        guard let hotDelegate = try? await hotDelegateSigner.publicKey(), hotDelegate == vault.hotDelegate else {
            return .rekeyRequired(vault)
        }

        return .ready(vault)
    }

    func update(state: CollectiblesState) {
        // Every emission re-triggers the accounts pipeline's CombineLatest — don't re-publish sameness
        guard state != stateSubject.value else {
            return
        }

        stateSubject.send(state)
    }
}

/// Keeps the unimplemented operations inert: a caller gets a throw, never a silent success.
private struct NotImplementedError: Error {}
