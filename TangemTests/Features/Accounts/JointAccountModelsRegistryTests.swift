//
//  JointAccountModelsRegistryTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import TangemFoundation
@testable import Tangem

// MARK: - Tests

/// What the registry does with a joint account across the reads of the two halves it is kept in.
@Suite("Tests for keeping the models of a wallet's joint accounts")
struct JointAccountModelsRegistryTests {
    @Test("A record moving on reaches the model that was handed out, rather than a fresh one nobody holds yet")
    func recordChangesReachTheModelHandedOut() async throws {
        let sut = Self.makeSUT()
        let delegate = JointAccountModelDelegateMock()
        let entry = Self.storedCryptoAccount()

        let first = await sut.jointAccountModels(
            from: [entry],
            with: [Self.storedJointAccount(status: .pending, memberNames: ["Alice"])],
            delegate: delegate
        )
        let model = try #require(first.first)
        let didChangeCount = OSAllocatedUnfairLock(initialState: 0)
        let subscription = model.didChangePublisher.sink { didChangeCount.withLock { $0 += 1 } }

        let second = await sut.jointAccountModels(
            from: [entry],
            with: [Self.storedJointAccount(status: .confirming(safeAddress: Self.safeAddress), memberNames: ["Alice", "Bob"])],
            delegate: delegate
        )

        #expect(second.count == 1)
        #expect(second.first === model)
        #expect(model.status == .confirming(safeAddress: Self.safeAddress))
        #expect(didChangeCount.withLock { $0 } == 1)
        withExtendedLifetime(subscription) {}
    }

    @Test("An entry whose record has not arrived yet builds nothing, its dependencies included")
    func entryWithoutRecordBuildsNothing() async {
        let dependenciesFactory = JointAccountDependenciesFactoryStub()
        let sut = Self.makeSUT(dependenciesFactory: dependenciesFactory)
        let delegate = JointAccountModelDelegateMock()

        let models = await sut.jointAccountModels(
            from: [Self.storedCryptoAccount()],
            with: [],
            delegate: delegate
        )

        #expect(models.isEmpty)
        #expect(dependenciesFactory.makeDependenciesCallsCount == 0)
    }
}

// MARK: - Helpers

private extension JointAccountModelsRegistryTests {
    static let safeAddress = "0x8f3a1C5E7B9D0246A8C0E2B4D6F8A0C2E4B6c21b"
    static let userWalletId = UserWalletId(value: Data(repeating: 0xAB, count: 32))
    static let derivationIdentity = CryptoAccountDerivationIdentity(derivationIndex: 1, type: .joint)

    static func makeSUT(
        dependenciesFactory: JointAccountDependenciesFactory = JointAccountDependenciesFactoryStub()
    ) -> JointAccountModelsRegistry {
        JointAccountModelsRegistry(userWalletId: userWalletId, dependenciesFactory: dependenciesFactory)
    }

    static func storedCryptoAccount() -> StoredCryptoAccount {
        StoredCryptoAccount(
            derivationIndex: derivationIdentity.derivationIndex,
            type: .joint,
            name: "Vacation fund",
            icon: StoredCryptoAccount.Icon(iconName: "Star", iconColor: "Azure"),
            tokens: [],
            grouping: .none,
            sorting: .manual
        )
    }

    static func storedJointAccount(status: JointAccountStatus, memberNames: [String]) -> StoredJointAccount {
        StoredJointAccount(
            cryptoAccountId: CryptoAccountModelId(userWalletId: userWalletId, derivationIdentity: derivationIdentity).rawValue.hexString,
            membersCount: 3,
            threshold: 2,
            status: status,
            members: memberNames.enumerated().map { index, name in
                StoredJointAccount.Member(
                    name: name,
                    address: "0x8f3a1C5E7B9D0246A8C0E2B4D6F8A0C2E4B6c21\(index)",
                    role: index == 0 ? .creator : .member,
                    inviteId: nil
                )
            }
        )
    }
}

// MARK: - Test doubles

private final class JointAccountDependenciesFactoryStub: JointAccountDependenciesFactory {
    private let callsCount = OSAllocatedUnfairLock(initialState: 0)

    var makeDependenciesCallsCount: Int {
        callsCount.withLock { $0 }
    }

    func makeDependencies(
        forAccountWithDerivationIdentity derivationIdentity: CryptoAccountDerivationIdentity
    ) -> JointAccountDependencies {
        callsCount.withLock { $0 += 1 }

        let walletModelsManager = WalletModelsManagerMock()
        let pendingOperationsProvider = JointAccountPendingOperationsProviderMock()

        return JointAccountDependencies(
            userTokensManager: UserTokensManagerMock(),
            walletModelsManager: walletModelsManager,
            walletModelsFactoryInput: WalletModelsFactoryInputStub(),
            derivationManager: nil,
            operationsService: JointAccountOperationsServiceMock(),
            pendingOperationsProvider: pendingOperationsProvider,
            finishedOperationsWalletUpdater: JointAccountFinishedOperationsWalletUpdater(
                pendingOperationsProvider: pendingOperationsProvider,
                walletModelsManager: walletModelsManager
            ),
            membersService: JointAccountMembersServiceMock()
        )
    }
}

private struct WalletModelsFactoryInputStub: WalletModelsFactoryInput {
    func setCryptoAccount(_ cryptoAccount: any CryptoAccountModel) {}
}
