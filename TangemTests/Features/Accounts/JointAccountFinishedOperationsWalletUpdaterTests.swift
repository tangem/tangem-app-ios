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
        let (repository, walletModels, updater) = makeSUT()

        repository.store(pendingOperations: [JointAccountCompositionFixture.pendingOperationsRecord(operations: remainingOperations)])

        #expect(walletModels.coin.updateAfterSendingTransactionSilentFlags == [true])
        #expect(walletModels.token.updateAfterSendingTransactionSilentFlags == [true])
        #expect(walletModels.otherNetwork.updateAfterSendingTransactionCallCount == 0)
        withExtendedLifetime(updater) {}
    }

    @Test("Nothing is updated while the operation is still in flight")
    func nothingIsUpdatedWhileInFlight() {
        let (repository, walletModels, updater) = makeSUT()

        repository.store(pendingOperations: [
            JointAccountCompositionFixture.pendingOperationsRecord(operations: [JointAccountCompositionFixture.coinTransfer(status: .pending)]),
        ])

        #expect(walletModels.coin.updateAfterSendingTransactionCallCount == 0)
        #expect(walletModels.token.updateAfterSendingTransactionCallCount == 0)
        withExtendedLifetime(updater) {}
    }
}

// MARK: - Helpers

private extension JointAccountFinishedOperationsWalletUpdaterTests {
    typealias WalletModels = (coin: WalletModelTestsMock, token: WalletModelTestsMock, otherNetwork: WalletModelTestsMock)

    static let ethereum = BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil)

    func makeSUT() -> (JointAccountsRepositoryStub, WalletModels, JointAccountFinishedOperationsWalletUpdater) {
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

        let repository = JointAccountsRepositoryStub(pendingOperations: [
            JointAccountCompositionFixture.pendingOperationsRecord(operations: [JointAccountCompositionFixture.coinTransfer()]),
        ])

        let updater = JointAccountFinishedOperationsWalletUpdater(
            pendingOperationsProvider: CommonJointAccountPendingOperationsProvider(
                userWalletId: JointAccountCompositionFixture.userWalletId,
                derivationIdentity: JointAccountCompositionFixture.derivationIdentity,
                jointAccountsRepository: repository,
                walletModelsManager: walletModelsManager
            ),
            walletModelsManager: walletModelsManager
        )

        return (repository, walletModels, updater)
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
            accountStatus: .active(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"),
            operationsService: JointAccountOperationsServiceMock(),
            pendingOperationsProvider: JointAccountPendingOperationsProviderMock(),
            membersService: JointAccountMembersServiceMock(),
            delegate: delegate
        )
    }
}
