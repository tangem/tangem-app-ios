//
//  WalletModelJointAccountPendingTransactionsTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import BigInt
import BlockchainSdk
import TangemFoundation
@testable import Tangem

// MARK: - Tests

@Suite("Tests for a joint account's unfinished operations counting as pending transactions of its wallets")
struct WalletModelJointAccountPendingTransactionsTests {
    private let delegate = JointAccountModelDelegateMock()

    @Test("An operation underway in the wallet's network is a pending transaction of the wallet and of the network")
    func operationUnderwayInTheNetworkCounts() throws {
        let provider = PendingOperationsProviderStub()
        let account = makeJointAccount(provider: provider)
        let sut = Self.makeWalletModel(account: account)

        try provider.send([Self.makeOperation(in: account, tokenItem: Self.coin)])

        #expect(sut.pendingTransactionsProvider.hasBlockingPendingTransactions)
        #expect(sut.pendingTransactionsProvider.hasAnyBlockingPendingTransactions)
        withExtendedLifetime(account) {}
    }

    @Test("An operation underway in another network is no pending transaction of this wallet")
    func operationUnderwayInAnotherNetworkDoesNotCount() throws {
        let provider = PendingOperationsProviderStub()
        let account = makeJointAccount(provider: provider)
        let sut = Self.makeWalletModel(account: account)

        try provider.send([Self.makeOperation(in: account, tokenItem: Self.polygonCoin)])

        #expect(!sut.pendingTransactionsProvider.hasBlockingPendingTransactions)
        #expect(!sut.pendingTransactionsProvider.hasAnyBlockingPendingTransactions)
        withExtendedLifetime(account) {}
    }

    @Test("An operation that is over is no pending transaction of the wallet")
    func operationThatIsOverDoesNotCount() throws {
        let provider = PendingOperationsProviderStub()
        let account = makeJointAccount(provider: provider)
        let sut = Self.makeWalletModel(account: account)

        try provider.send([Self.makeOperation(in: account, tokenItem: Self.coin, status: .executed)])

        #expect(!sut.pendingTransactionsProvider.hasBlockingPendingTransactions)
        #expect(!sut.pendingTransactionsProvider.hasAnyBlockingPendingTransactions)
        withExtendedLifetime(account) {}
    }

    @Test("A wallet of one of the wallet's own accounts has no operations to count")
    func walletOfOwnAccountCountsNothing() {
        let account = CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in })
        let sut = Self.makeWalletModel(account: account)

        #expect(!sut.pendingTransactionsProvider.hasBlockingPendingTransactions)
        #expect(!sut.pendingTransactionsProvider.hasAnyBlockingPendingTransactions)
    }
}

// MARK: - Helpers

private extension WalletModelJointAccountPendingTransactionsTests {
    static let ethereum = BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil)
    static let coin: TokenItem = .blockchain(ethereum)
    static let polygonCoin: TokenItem = .blockchain(BlockchainNetwork(.polygon(testnet: false), derivationPath: nil))
    static let creatorAddress = "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf"
    static let safeAddress = "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"
    static let recipient = "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c"

    static func makeWalletModel(account: any CryptoAccountModel) -> CommonWalletModel {
        let walletManager = EthereumWalletManagerMock()
        let walletModel = CommonWalletModel(
            userWalletId: UserWalletId(value: Data(repeating: 0xAB, count: 32)),
            tokenItem: coin,
            walletManager: walletManager,
            stakingManager: nil,
            isYieldModuleSupported: false,
            featureManager: WalletModelFeaturesManagerMock(),
            pendingTransactionsProvider: CommonPendingTransactionsProvider(walletProvider: walletManager, tokenItem: coin),
            transactionHistoryUpdater: TransactionHistoryUpdater(),
            transactionHistoryService: nil,
            receiveAddressService: DummyReceiveAddressService(addressInfos: []),
            tokenBalancesRepository: TokenBalancesRepositoryMock(),
            isCustom: false
        )
        walletModel.setCryptoAccount(account)

        return walletModel
    }

    static func makeOperation(
        in account: any JointAccountModel,
        tokenItem: TokenItem,
        status: JointAccountOperationStatus = .awaitingSignatures
    ) throws -> JointAccountPendingOperation {
        let wallet = try JointAccountWalletBuilder().build(
            walletModel: WalletModelTestsMock(
                tokenItem: tokenItem,
                isEmpty: false,
                account: account,
                safeWalletManagerOperationsService: SafeWalletManagerOperationsServiceTestsMock()
            )
        )

        return JointAccountPendingOperation(
            wallet: wallet,
            initiator: .unlisted(address: creatorAddress),
            operation: JointAccountCompositionFixture.coinTransfer(status: status, initiator: creatorAddress),
            innerCallType: .transfer(.coin(destination: recipient, value: 1_000_000_000_000_000)),
            feeTokenItem: tokenItem,
            handleProvider: JointAccountPendingOperationHandleProviderStub()
        )
    }

    func makeJointAccount(provider: any JointAccountPendingOperationsProvider) -> any JointAccountModel {
        CommonJointAccountModel(
            cryptoAccount: CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in }),
            derivationIdentity: CryptoAccountDerivationIdentity(derivationIndex: 1, type: .joint),
            accountPolicy: JointAccountPolicy(membersCount: 2, signersCount: 2),
            statusProvider: JointAccountStatusProviderStub(status: .active(safeAddress: Self.safeAddress)),
            operationsService: JointAccountOperationsServiceMock(),
            pendingOperationsProvider: provider,
            membersService: JointAccountMembersServiceMock(
                slots: [.member(JointAccountMember(name: "Isaac", address: Self.creatorAddress, role: .creator, isMe: false, signature: nil), .active)]
            ),
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

// MARK: - Stubs

private final class PendingOperationsProviderStub: JointAccountPendingOperationsProvider {
    private let operationsSubject = CurrentValueSubject<[JointAccountPendingOperation], Never>([])

    var pendingOperationsPublisher: AnyPublisher<[JointAccountPendingOperation], Never> {
        operationsSubject.eraseToAnyPublisher()
    }

    func send(_ operations: [JointAccountPendingOperation]) {
        operationsSubject.send(operations)
    }

    func requestFrequentUpdates(operationId: String) -> AnyCancellable? {
        nil
    }

    func pendingOperation(from operation: JointAccountOperation) async throws -> JointAccountPendingOperation {
        throw "Not called by these tests"
    }

    func loadOperation(id: String) async throws -> JointAccountPendingOperation {
        throw "Not called by these tests"
    }
}
