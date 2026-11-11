//
//  CollectiblesAccountListWriterTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemFoundation
@testable import Tangem

@Suite("CollectiblesAccountModelsRegistry.AccountListWriter")
struct CollectiblesAccountListWriterTests {
    @Test("A new Packs account is added first in a single write")
    func newPacksAccountGoesFirst() async {
        let mainAccount = Self.storedAccount(derivationIndex: 0)
        let secondAccount = Self.storedAccount(derivationIndex: 1)
        let repository = CryptoAccountsRepositorySpy(accounts: [mainAccount, secondAccount])
        let packsConfig = CollectiblesAccountModelsRegistry.AccountListUpdater.persistentConfig

        await CollectiblesAccountModelsRegistry.AccountListWriter(cryptoAccountsRepository: repository).add(packsConfig)

        #expect(repository.additions.map(\.identity) == [packsConfig.derivationIdentity])
        #expect(repository.additions.map(\.placement) == [.first])
        #expect(repository.reorders.isEmpty)
    }

    @Test("The Packs account is identified like its account list entry, so reordering finds it")
    func packsAccountIdMatchesItsEntry() {
        let packsConfig = CollectiblesAccountModelsRegistry.AccountListUpdater.persistentConfig

        #expect(Self.packsAccountId.toPersistentIdentifier() == packsConfig.derivationIdentity.toPersistentIdentifier())
    }
}

// MARK: - Helpers

private extension CollectiblesAccountListWriterTests {
    static let packsAccountId = CollectiblesAccountId(
        userWalletId: UserWalletId(value: Data(repeating: 7, count: 32))
    )

    struct Account {
        let config: CryptoAccountPersistentConfig
        let stored: StoredCryptoAccount
    }

    static func storedAccount(derivationIndex: Int) -> Account {
        let config = CryptoAccountPersistentConfig(
            derivationIdentity: CryptoAccountDerivationIdentity(derivationIndex: derivationIndex, type: .crypto),
            name: "Account \(derivationIndex)",
            icon: AccountModel.CompositeIcon(name: .package, color: .azure)
        )

        return Account(config: config, stored: StoredCryptoAccount(config: config, tokenListAppearance: .default, tokens: []))
    }
}

private final class CryptoAccountsRepositorySpy: CryptoAccountsRepository {
    struct Addition {
        let identity: CryptoAccountDerivationIdentity
        let placement: StoredCryptoAccountsMerger.NewAccountsPlacement
    }

    private(set) var additions: [Addition] = []
    private(set) var reorders: [[AnyHashable]] = []

    private let accounts: [StoredCryptoAccount]

    init(accounts: [CollectiblesAccountListWriterTests.Account]) {
        self.accounts = accounts.map(\.stored)
    }

    var hasSyncedWithRemotePublisher: AnyPublisher<Bool, Never> {
        Just(true).eraseToAnyPublisher()
    }

    var cryptoAccounts: [StoredCryptoAccount] {
        accounts
    }

    var cryptoAccountsPublisher: AnyPublisher<[StoredCryptoAccount], Never> {
        Just(accounts).eraseToAnyPublisher()
    }

    var auxiliaryDataPublisher: AnyPublisher<CryptoAccountsAuxiliaryData, Never> {
        Empty().eraseToAnyPublisher()
    }

    func initialize(forUserWalletWithId userWalletId: UserWalletId) {}

    func getRemoteState() async throws -> CryptoAccountsRemoteState {
        CryptoAccountsRemoteState(nextCryptoDerivationIndex: accounts.count, nextJointDerivationIndex: nil, accounts: accounts)
    }

    func loadCryptoAccountsFromRemote() async throws {}

    func addNewCryptoAccount(
        withConfig config: CryptoAccountPersistentConfig,
        remoteState: CryptoAccountsRemoteState,
        placement: StoredCryptoAccountsMerger.NewAccountsPlacement
    ) async throws -> StoredCryptoAccountsTokensDistributor.DistributionResult {
        additions.append(Addition(identity: config.derivationIdentity, placement: placement))
        return .none
    }

    func updateExistingCryptoAccount(
        withConfig config: CryptoAccountPersistentConfig,
        remoteState: CryptoAccountsRemoteState
    ) async throws {}

    func removeCryptoAccount(withIdentifier identifier: some Hashable) async throws {}

    func reorderCryptoAccounts(orderedIdentifiers: [some Hashable]) async throws {
        reorders.append(orderedIdentifiers.map { $0.toAnyHashable() })
    }
}
