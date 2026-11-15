//
//  AccountPickerUserWalletsProviderTests.swift
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

@Suite("AccountPicker user wallets provider")
struct AccountPickerUserWalletsProviderTests {
    private let delegate = JointAccountModelDelegateMock()

    @Test("Crypto accounts leave joint accounts out")
    func cryptoAccountsLeaveJointOut() async {
        let mainAccount = makeAccount(isMain: true)
        let userWallet = makeUserWallet("userWallet", accountModels: [.standard(.single(mainAccount)), .joint([makeJointAccount(isActive: true)])])

        let userWallets = await record(.cryptoAccounts(in: UserWalletsProviderStub(userWallets: [userWallet])))

        #expect(accountIds(of: userWallets.last) == [[mainAccount.id.toAnyHashable()]])
    }

    @Test("Crypto and joint accounts take the active joint accounts and leave the pending ones out")
    func cryptoJointAccountsTakeActiveJointOnly() async {
        let mainAccount = makeAccount(isMain: true)
        let activeJointAccount = makeJointAccount(isActive: true)
        let userWallet = makeUserWallet(
            "userWallet",
            accountModels: [.standard(.single(mainAccount)), .joint([activeJointAccount, makeJointAccount(isActive: false)])]
        )

        let userWallets = await record(.cryptoJointAccounts(in: UserWalletsProviderStub(userWallets: [userWallet])))

        #expect(accountIds(of: userWallets.last) == [[mainAccount.id.toAnyHashable(), activeJointAccount.id.toAnyHashable()]])
    }

    @Test("A new account reaches the user wallets and the user wallets keep their order")
    func newAccountReachesUserWalletsInStableOrder() async {
        let firstManager = SelectorAccountModelsManagerStub(accountModels: [.standard(.single(makeAccount(isMain: true)))])
        let first = SelectorUserWalletModelStub(idSeed: "first", accountModelsManager: firstManager)
        let last = makeUserWallet("last", accounts: makeCryptoAccounts(count: 1))
        let newAccount = makeAccount(isMain: false)

        let userWallets = await record(.cryptoAccounts(in: UserWalletsProviderStub(userWallets: [first, last]))) {
            firstManager.send([.standard(.multiple([makeAccount(isMain: true), newAccount]))])
        }

        #expect(userWallets.last?.map(\.userWalletModel.userWalletId) == [first.userWalletId, last.userWalletId])
        #expect(accountIds(of: userWallets.last).first?.contains(newAccount.id.toAnyHashable()) == true)
    }

    @Test("A user wallet whose accounts are still loading doesn't hold back the others")
    func pendingUserWalletDoesNotBlockOthers() async {
        let pending = SelectorUserWalletModelStub(idSeed: "pending", accountModelsManager: SelectorAccountModelsManagerStub(accountModels: nil))
        let ready = makeUserWallet("ready", accounts: makeCryptoAccounts(count: 1))

        let userWallets = await record(.cryptoAccounts(in: UserWalletsProviderStub(userWallets: [pending, ready])))

        #expect(userWallets.last?.map(\.userWalletModel.userWalletId) == [ready.userWalletId])
    }

    @Test("A real locked user wallet stays, with no accounts")
    func realLockedUserWalletStays() async {
        let locked = makeLockedUserWalletModel(idSeed: "locked")
        let userWallet = makeUserWallet("userWallet", accounts: makeCryptoAccounts(count: 1))

        let userWallets = await record(.cryptoAccounts(in: UserWalletsProviderStub(userWallets: [locked, userWallet])))

        #expect(userWallets.last?.map(\.userWalletModel.userWalletId) == [locked.userWalletId, userWallet.userWalletId])
        #expect(userWallets.last?.map(\.accounts.count) == [0, 1])
    }
}

// MARK: - Helpers

private extension AccountPickerUserWalletsProviderTests {
    func record(
        _ provider: any AccountPickerUserWalletsProvider,
        afterSubscribing action: () -> Void = {}
    ) async -> [[AccountPickerUserWallet]] {
        await withSelectorDependencies(userWalletModels: []) {
            var emissions: [[AccountPickerUserWallet]] = []
            let subscription = provider.userWalletsPublisher.sink { emissions.append($0) }
            action()
            subscription.cancel()
            return emissions
        }
    }

    func accountIds(of userWallets: [AccountPickerUserWallet]?) -> [[AnyHashable]] {
        (userWallets ?? []).map { userWallet in
            userWallet.accounts.map { $0.id.toAnyHashable() }
        }
    }

    func makeAccount(isMain: Bool) -> CryptoAccountModelMock {
        CryptoAccountModelMock(isMainAccount: isMain, onArchive: { _ in })
    }

    func makeCryptoAccounts(count: Int) -> [any CryptoAccountModel] {
        (0 ..< count).map { makeAccount(isMain: $0 == 0) }
    }

    func makeJointAccount(isActive: Bool) -> any JointAccountModel {
        CommonJointAccountModel(
            cryptoAccount: CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in }),
            derivationIdentity: CryptoAccountDerivationIdentity(derivationIndex: 1, type: .joint),
            accountPolicy: JointAccountPolicy(membersCount: 3, signersCount: 2),
            statusProvider: JointAccountStatusProviderStub(status: isActive ? .active(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b") : .pending),
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

    func makeUserWallet(_ idSeed: String, isLocked: Bool = false, accounts: [any CryptoAccountModel]) -> SelectorUserWalletModelStub {
        let accountModels: [AccountModel] = switch accounts.count {
        case 0: []
        case 1: [.standard(.single(accounts[0]))]
        default: [.standard(.multiple(accounts))]
        }

        return makeUserWallet(idSeed, isLocked: isLocked, accountModels: accountModels)
    }

    func makeUserWallet(_ idSeed: String, isLocked: Bool = false, accountModels: [AccountModel]) -> SelectorUserWalletModelStub {
        SelectorUserWalletModelStub(
            idSeed: idSeed,
            isLocked: isLocked,
            accountModelsManager: SelectorAccountModelsManagerStub(accountModels: accountModels)
        )
    }
}

// MARK: - Stubs

private struct UserWalletsProviderStub: UserWalletSelectorUserWalletsProvider {
    let userWallets: [any UserWalletModel]

    var userWalletModels: [any UserWalletModel] { userWallets }
}
