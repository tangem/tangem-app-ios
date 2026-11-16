//
//  UserSettingsAccountsViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import TangemFoundation
import TangemTestKit
@testable import Tangem

// MARK: - Tests

@Suite("Accounts list on the wallet settings screen", .timeLimit(.minutes(1)))
@MainActor
final class UserSettingsAccountsViewModelTests: LeakTrackingTestSuite {
    private let delegate = JointAccountModelDelegateMock()

    @Test("A joint account paused for safety is listed as a paused row next to the working accounts")
    func pausedJointAccountIsListedAsPausedRow() async throws {
        let standard = CryptoAccountModelMock(isMainAccount: true, onArchive: { _ in })
        let working = makeJointAccount(statusProvider: JointAccountStatusProviderStub(status: Constants.activeStatus))
        let paused = makeJointAccount(statusProvider: JointAccountStatusProviderStub(status: .untrusted))
        let (sut, _) = makeSUT(accountModelsManager: SelectorAccountModelsManagerStub(
            accountModels: [.standard(.single(standard)), .joint([working, paused])]
        ))

        let rows = try #require(await sut.$accountRows.values.first { $0.isNotEmpty })

        #expect(rows.map(ListedRow.init) == [
            ListedRow(id: standard.id.toAnyHashable(), isPaused: false),
            ListedRow(id: working.id.toAnyHashable(), isPaused: false),
            ListedRow(id: paused.id.toAnyHashable(), isPaused: true),
        ])
    }

    @Test("Tapping a paused row asks for the paused account alert instead of opening the account")
    func tappingPausedRowShowsAlert() async throws {
        let paused = makeJointAccount(statusProvider: JointAccountStatusProviderStub(status: .untrusted))
        let (sut, coordinator) = makeSUT(accountModelsManager: SelectorAccountModelsManagerStub(accountModels: [.joint([paused])]))

        let rows = try #require(await sut.$accountRows.values.first { $0.isNotEmpty })
        guard case .paused(let rowViewModel) = try #require(rows.first).content else {
            Issue.record("The paused joint account is not listed as a paused row")
            return
        }

        rowViewModel.onSelect()

        #expect(coordinator.calls == [.showPausedJointAccountAlert])
    }

    @Test(
        "A listed joint account whose status changes is listed again as the row of its new status",
        arguments: [
            (Constants.activeStatus, JointAccountStatus.untrusted, true),
            (JointAccountStatus.untrusted, Constants.activeStatus, false),
        ]
    )
    func jointAccountIsRelistedOnStatusChange(
        initialStatus: JointAccountStatus,
        changedStatus: JointAccountStatus,
        isPausedAfterChange: Bool
    ) async throws {
        let statusProvider = JointAccountStatusSubjectStub(status: initialStatus)
        let jointAccount = makeJointAccount(statusProvider: statusProvider)
        let accountModelsManager = SelectorAccountModelsManagerStub(accountModels: [.joint([jointAccount])])
        let (sut, _) = makeSUT(accountModelsManager: accountModelsManager)
        _ = await sut.$accountRows.values.first { $0.isNotEmpty }

        statusProvider.send(changedStatus)
        accountModelsManager.send([.joint([jointAccount])])
        let rows = try #require(await sut.$accountRows.dropFirst().values.first { _ in true })

        #expect(rows.map(ListedRow.init) == [ListedRow(id: jointAccount.id.toAnyHashable(), isPaused: isPausedAfterChange)])
    }
}

// MARK: - Helpers

private extension UserSettingsAccountsViewModelTests {
    enum Constants {
        static let activeStatus = JointAccountStatus.active(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b")
    }

    struct ListedRow: Equatable {
        let id: AnyHashable
        let isPaused: Bool
    }

    func makeSUT(
        accountModelsManager: SelectorAccountModelsManagerStub
    ) -> (UserSettingsAccountsViewModel, UserSettingsAccountsRoutableSpy) {
        let coordinator = UserSettingsAccountsRoutableSpy()
        let sut = UserSettingsAccountsViewModel(
            accountModelsManager: accountModelsManager,
            userWalletConfig: UserWalletConfigStub(),
            coordinator: coordinator
        )

        return (trackForMemoryLeaks(sut), coordinator)
    }

    func makeJointAccount(statusProvider: any JointAccountStatusProvider) -> any JointAccountModel {
        CommonJointAccountModel(
            cryptoAccount: CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in }),
            derivationIdentity: CryptoAccountDerivationIdentity(derivationIndex: 1, type: .joint),
            accountPolicy: JointAccountPolicy(membersCount: 3, signersCount: 2),
            statusProvider: statusProvider,
            operationsService: JointAccountOperationsServiceMock(),
            pendingOperationsProvider: JointAccountPendingOperationsProviderMock(),
            membersService: JointAccountMembersServiceMock(),
            finishedOperationsWalletUpdater: JointAccountFinishedOperationsWalletUpdater(
                pendingOperationsProvider: JointAccountPendingOperationsProviderMock(),
                walletModelsManager: WalletModelsManagerMock(),
                historyDeltaSyncing: JointOperationsHistoryDeltaSyncingStub()
            ),
            userRoleService: JointAccountUserRoleServiceMock(),
            delegate: delegate
        )
    }
}

private extension UserSettingsAccountsViewModelTests.ListedRow {
    init(_ accountRow: UserSettingsAccountsViewModel.AccountRow) {
        id = accountRow.id
        isPaused = accountRow.content.isPaused
    }
}

// MARK: - Stubs

private final class JointAccountStatusSubjectStub: JointAccountStatusProvider {
    private let statusSubject: CurrentValueSubject<JointAccountStatus, Never>

    init(status: JointAccountStatus) {
        statusSubject = CurrentValueSubject(status)
    }

    var status: JointAccountStatus {
        statusSubject.value
    }

    var statusPublisher: AnyPublisher<JointAccountStatus, Never> {
        statusSubject.eraseToAnyPublisher()
    }

    func send(_ status: JointAccountStatus) {
        statusSubject.send(status)
    }
}

private final class UserSettingsAccountsRoutableSpy: UserSettingsAccountsRoutable {
    enum Call: Equatable {
        case openAccountDetails
        case showPausedJointAccountAlert
    }

    private(set) var calls: [Call] = []

    func addNewAccount() {}

    func openAddAccountTypeSelector(userWalletConfig: UserWalletConfig) {}

    func openManageTokens(
        accountModelsManager: any AccountModelsManager,
        cryptoAccountModel: any CryptoAccountModel,
        userWalletConfig: UserWalletConfig
    ) {}

    func openAccountDetails(
        account: any BaseAccountModel,
        accountModelsManager: any AccountModelsManager,
        userWalletConfig: UserWalletConfig
    ) {
        calls.append(.openAccountDetails)
    }

    func openArchivedAccounts(accountModelsManager: any AccountModelsManager) {}

    func handleAccountsLimitReached() {}

    func showPausedJointAccountAlert() {
        calls.append(.showPausedJointAccountAlert)
    }

    func handleAccountsRedistribution(sourceAccountName: String, targetAccountName: String) {}
}
