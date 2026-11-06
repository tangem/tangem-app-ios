//
//  UserWalletSelectorUserWalletsProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemAccounts
@testable import Tangem

@Suite("UserWalletSelector user wallets providers")
struct UserWalletSelectorUserWalletsProviderTests {
    private let jointAccountDelegate = JointAccountModelDelegateMock()

    @Test("All user wallets come in the repository order, locked ones included")
    func allUserWalletsKeepRepositoryOrderWithLocked() async {
        let userWallets = [makeUserWallet("first"), makeUserWallet("locked", isLocked: true), makeUserWallet("last")]

        let ids = await withSelectorDependencies(userWalletModels: userWallets) {
            AllUserWalletsProvider().userWalletModels.map(\.userWalletId)
        }

        #expect(ids == userWallets.map(\.userWalletId))
    }

    @Test("Account creation availability shows a full user wallet as unavailable instead of hiding it", arguments: [AccountType.crypto, .joint])
    func accountCreationMarksFullUserWallet(accountType: AccountType) {
        let provider: any UserWalletSelectorAvailabilityProvider = .accountCreation(accountType)
        let full = accountType == .crypto
            ? makeUserWallet("full", accountsCount: AccountModelUtils.maxNumberOfAccounts(for: .crypto))
            : makeUserWallet("full", jointAccountsCount: AccountModelUtils.maxNumberOfAccounts(for: .joint))

        #expect(provider.availability(of: full) == .unavailable(.accountsLimitReached(for: accountType)))
        #expect(provider.availability(of: makeUserWallet("candidate")) == .available)
        #expect(provider.availability(of: makeUserWallet("locked", isLocked: true)) == .locked)
    }

    @Test("A user wallet full of joint accounts is still available for a crypto account")
    func fullJointUserWalletAvailableForCryptoAccount() {
        let full = makeUserWallet("full", jointAccountsCount: AccountModelUtils.maxNumberOfAccounts(for: .joint))
        let jointProvider: any UserWalletSelectorAvailabilityProvider = .accountCreation(.joint)
        let cryptoProvider: any UserWalletSelectorAvailabilityProvider = .accountCreation(.crypto)

        #expect(jointProvider.availability(of: full) == .unavailable(.accountsLimitReached(for: .joint)))
        #expect(cryptoProvider.availability(of: full) == .available)
    }

    @Test("The lock state availability marks a locked user wallet as locked")
    func lockStateAvailability() {
        let provider: any UserWalletSelectorAvailabilityProvider = .lockState()

        #expect(provider.availability(of: makeUserWallet("locked", isLocked: true)) == .locked)
        #expect(provider.availability(of: makeUserWallet("unlocked")) == .available)
    }
}

// MARK: - Helpers

private extension UserWalletSelectorUserWalletsProviderTests {
    func makeUserWallet(
        _ idSeed: String,
        isLocked: Bool = false,
        accountsCount: Int = 1,
        jointAccountsCount: Int = 0
    ) -> SelectorUserWalletModelStub {
        let accounts = (0 ..< accountsCount).map { index in
            CryptoAccountModelMock(isMainAccount: index == 0, onArchive: { _ in })
        }
        let jointAccounts = (0 ..< jointAccountsCount).map { index in
            makeJointAccount(derivationIndex: index + 1)
        }

        return SelectorUserWalletModelStub(
            idSeed: idSeed,
            isLocked: isLocked,
            accountModelsManager: SelectorAccountModelsManagerStub(accountModels: [.standard(.multiple(accounts)), .joint(jointAccounts)])
        )
    }

    func makeJointAccount(derivationIndex: Int) -> any JointAccountModel {
        CommonJointAccountModel(
            cryptoAccount: CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in }),
            derivationIdentity: CryptoAccountDerivationIdentity(derivationIndex: derivationIndex, type: .joint),
            accountPolicy: JointAccountPolicy(membersCount: 3, signersCount: 2),
            statusProvider: JointAccountStatusProviderStub(status: .active(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b")),
            operationsService: JointAccountOperationsServiceMock(),
            pendingOperationsProvider: JointAccountPendingOperationsProviderMock(),
            membersService: JointAccountMembersServiceMock(),
            finishedOperationsWalletUpdater: JointAccountFinishedOperationsWalletUpdater(
                pendingOperationsProvider: JointAccountPendingOperationsProviderMock(),
                walletModelsManager: WalletModelsManagerMock(),
                historyDeltaSyncing: JointOperationsHistoryDeltaSyncingStub()
            ),
            userRoleService: JointAccountUserRoleServiceMock(),
            delegate: jointAccountDelegate
        )
    }
}
