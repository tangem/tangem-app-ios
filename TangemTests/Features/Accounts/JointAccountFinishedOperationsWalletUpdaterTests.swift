//
//  JointAccountFinishedOperationsWalletUpdaterTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Testing
@testable import Tangem

@Suite("Tests for updating the wallets of a joint account once its operation is done")
struct JointAccountFinishedOperationsWalletUpdaterTests {
    private let delegate = JointAccountModelDelegateMock()

    @Test(
        "Every wallet in the operation's network is updated once the operation is done",
        arguments: [[], [JointAccountCompositionFixture.coinTransfer(status: .executed)]]
    )
    func walletsInTheNetworkAreUpdated(remainingOperations: [JointAccountOperation]) {
        let (repository, walletModels, _, updater) = makeSUT()

        repository.store(pendingOperations: [JointAccountCompositionFixture.pendingOperationsRecord(operations: remainingOperations)])

        #expect(walletModels.coin.updateAfterSendingTransactionSilentFlags == [true])
        #expect(walletModels.token.updateAfterSendingTransactionSilentFlags == [true])
        #expect(walletModels.otherNetwork.updateAfterSendingTransactionCallCount == 0)
        withExtendedLifetime(updater) {}
    }

    @Test("Nothing is updated while the operation is still in flight")
    func nothingIsUpdatedWhileInFlight() {
        let (repository, walletModels, _, updater) = makeSUT()

        repository.store(pendingOperations: [
            JointAccountCompositionFixture.pendingOperationsRecord(operations: [JointAccountCompositionFixture.coinTransfer(status: .pending)]),
        ])

        #expect(walletModels.coin.updateAfterSendingTransactionCallCount == 0)
        #expect(walletModels.token.updateAfterSendingTransactionCallCount == 0)
        withExtendedLifetime(updater) {}
    }

    @Test("The history delta is synced once the operation is done", .timeLimit(.minutes(1)))
    func historyDeltaIsSyncedOncePerEvent() async {
        let (repository, walletModels, historyDeltaSyncing, updater) = makeSUT()

        repository.store(pendingOperations: [JointAccountCompositionFixture.pendingOperationsRecord(operations: [])])

        for await _ in historyDeltaSyncing.syncDeltaCalls {
            break
        }

        #expect(walletModels.coin.updateAfterSendingTransactionCallCount == 1)
        #expect(walletModels.token.updateAfterSendingTransactionCallCount == 1)
        #expect(historyDeltaSyncing.syncDeltaCallsCount == 1)
        withExtendedLifetime(updater) {}
    }
}

// MARK: - Helpers

private extension JointAccountFinishedOperationsWalletUpdaterTests {
    typealias WalletModels = (coin: WalletModelTestsMock, token: WalletModelTestsMock, otherNetwork: WalletModelTestsMock)

    static let ethereum = BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil)

    func makeSUT() -> (
        JointAccountPendingOperationsRepositoryStub,
        WalletModels,
        JointOperationsHistoryDeltaSyncingStub,
        JointAccountFinishedOperationsWalletUpdater
    ) {
        let account = makeJointAccount()
        let walletModels: WalletModels = (
            coin: makeWalletModel(tokenItem: .blockchain(Self.ethereum), account: account),
            token: makeWalletModel(
                tokenItem: .token(
                    Token(name: "Tether", symbol: "USDT", contractAddress: "0xdAC17F958D2ee523a2206206994597C13D831ec7", decimalCount: 6),
                    Self.ethereum
                ),
                account: account
            ),
            otherNetwork: makeWalletModel(tokenItem: .blockchain(BlockchainNetwork(.polygon(testnet: false), derivationPath: nil)), account: account)
        )

        let walletModelsManager = WalletModelsManagerTestsMock()
        walletModelsManager.walletModels = [walletModels.coin, walletModels.token, walletModels.otherNetwork]
        walletModelsManager.sendUpdate()

        let repository = JointAccountPendingOperationsRepositoryStub(pendingOperations: [
            JointAccountCompositionFixture.pendingOperationsRecord(operations: [JointAccountCompositionFixture.coinTransfer()]),
        ])

        let historyDeltaSyncing = JointOperationsHistoryDeltaSyncingStub()
        let updater = JointAccountFinishedOperationsWalletUpdater(
            pendingOperationsProvider: CommonJointAccountPendingOperationsProvider(
                userWalletId: JointAccountCompositionFixture.userWalletId,
                derivationIdentity: JointAccountCompositionFixture.derivationIdentity,
                pendingOperationsRepository: repository,
                walletModelsManager: walletModelsManager,
                membersService: JointAccountMembersServiceMock()
            ),
            walletModelsManager: walletModelsManager,
            historyDeltaSyncing: historyDeltaSyncing
        )

        return (repository, walletModels, historyDeltaSyncing, updater)
    }

    func makeWalletModel(tokenItem: TokenItem, account: any CryptoAccountModel) -> WalletModelTestsMock {
        WalletModelTestsMock(
            tokenItem: tokenItem,
            isEmpty: false,
            account: account,
            safeWalletManagerOperationsService: SafeWalletManagerOperationsServiceTestsMock()
        )
    }

    func makeJointAccount() -> any JointAccountModel {
        CommonJointAccountModel(
            cryptoAccount: CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in }),
            derivationIdentity: JointAccountCompositionFixture.derivationIdentity,
            accountPolicy: JointAccountPolicy(membersCount: 2, signersCount: 2),
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
            delegate: delegate
        )
    }
}
