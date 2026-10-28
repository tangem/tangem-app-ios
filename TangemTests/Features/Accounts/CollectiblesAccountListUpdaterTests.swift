//
//  CollectiblesAccountListUpdaterTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemCollectibles
@testable import Tangem

@Suite("CollectiblesAccountModelsRegistry.AccountListUpdater")
struct CollectiblesAccountListUpdaterTests {
    @Test("Asks once to add an account whose vault is confirmed while the account list lacks it")
    func addsMissingAccountOnce() {
        let sut = makeSUT()

        sut.vaultState.send(.ready(Constants.vault))
        sut.vaultState.send(.rekeyRequired(Constants.vault))

        let addedIdentities = sut.additions.configs.map(\.derivationIdentity)
        #expect(addedIdentities == [Constants.collectiblesDerivationIdentity])
    }

    @Test("Leaves alone an account the account list already has")
    func skipsListedAccount() {
        let sut = makeSUT()

        sut.updater.update(isInAccountList: true)
        sut.vaultState.send(.ready(Constants.vault))

        #expect(sut.additions.configs.isEmpty)
    }

    @Test("Adds nothing while the account list can't keep the account's type")
    func skipsUntypedAccountList() {
        let sut = makeSUT(canAddToAccountList: false)

        sut.vaultState.send(.ready(Constants.vault))

        #expect(sut.additions.configs.isEmpty)
    }
}

// MARK: - Helpers

private extension CollectiblesAccountListUpdaterTests {
    typealias SUT = (
        updater: CollectiblesAccountModelsRegistry.AccountListUpdater,
        vaultState: CurrentValueSubject<CollectiblesState, Never>,
        additions: AdditionsRecorder
    )

    func makeSUT(canAddToAccountList: Bool = true) -> SUT {
        let vaultState = CurrentValueSubject<CollectiblesState, Never>(.unresolved)
        let additions = AdditionsRecorder()
        let updater = CollectiblesAccountModelsRegistry.AccountListUpdater(
            vaultStatePublisher: vaultState.eraseToAnyPublisher(),
            canAddToAccountList: canAddToAccountList,
            addToAccountList: additions.record
        )

        return (updater, vaultState, additions)
    }
}

// MARK: - Constants

private extension CollectiblesAccountListUpdaterTests {
    enum Constants {
        static let collectiblesDerivationIdentity = CryptoAccountDerivationIdentity(
            derivationIndex: 999_799,
            type: .collectibles
        )

        static let vault = CollectiblesVaultInfo(
            vaultAddress: "vault",
            sessionKey: Data(repeating: 1, count: 32),
            perSpinCap: 0,
            dailyCap: 0,
            spentToday: 0,
            dayIndex: 0
        )
    }
}

// MARK: - Doubles

private final class AdditionsRecorder {
    private(set) var configs: [CryptoAccountPersistentConfig] = []

    func record(_ config: CryptoAccountPersistentConfig) {
        configs.append(config)
    }
}
