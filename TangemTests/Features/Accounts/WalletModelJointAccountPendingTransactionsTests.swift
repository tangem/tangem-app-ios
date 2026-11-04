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
import BlockchainSdk
import TangemFoundation
@testable import Tangem

// MARK: - Tests

@Suite("Tests for a joint account's unfinished operations counting as pending transactions of its wallets")
struct WalletModelJointAccountPendingTransactionsTests {
    private let delegate = JointAccountModelDelegateMock()

    @Test("An operation underway in the wallet's network is a pending transaction of the wallet and of the network")
    func operationUnderwayInTheNetworkCounts() throws {
        let provider = try PendingOperationsProviderStub(chainIds: [#require(Self.coin.blockchain.chainId)])
        let account = makeJointAccount(provider: provider)
        let sut = Self.makeWalletModel(account: account)

        #expect(sut.hasPendingTransactions)
        #expect(sut.hasAnyPendingTransactions)
        withExtendedLifetime(account) {}
    }

    @Test("An operation underway in another network is no pending transaction of this wallet")
    func operationUnderwayInAnotherNetworkDoesNotCount() throws {
        let provider = try PendingOperationsProviderStub(chainIds: [#require(Blockchain.polygon(testnet: false).chainId)])
        let account = makeJointAccount(provider: provider)
        let sut = Self.makeWalletModel(account: account)

        #expect(!sut.hasPendingTransactions)
        #expect(!sut.hasAnyPendingTransactions)
        withExtendedLifetime(account) {}
    }

    @Test("A wallet of one of the wallet's own accounts has no operations to count")
    func walletOfOwnAccountCountsNothing() {
        let account = CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in })
        let sut = Self.makeWalletModel(account: account)

        #expect(!sut.hasPendingTransactions)
        #expect(!sut.hasAnyPendingTransactions)
    }
}

// MARK: - Helpers

private extension WalletModelJointAccountPendingTransactionsTests {
    static let ethereum = BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil)
    static let coin: TokenItem = .blockchain(ethereum)
    static let creatorAddress = "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf"
    static let safeAddress = "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"

    static func makeWalletModel(account: any CryptoAccountModel) -> CommonWalletModel {
        let mobileWalletInfo = MobileWalletInfo(
            hasMnemonicBackup: false,
            hasICloudBackup: false,
            hasSocialLogin: false,
            accessCodeStatus: .none,
            keys: []
        )
        let config = UserWalletConfigFactory().makeConfig(mobileWalletInfo: mobileWalletInfo)
        let walletModel = CommonWalletModel(
            userWalletId: UserWalletId(value: Data(repeating: 0xAB, count: 32)),
            tokenItem: coin,
            walletManager: EthereumWalletManagerMock(),
            stakingManager: nil,
            isYieldModuleSupported: false,
            featureManager: WalletModelFeaturesManagerMock(),
            transactionHistoryUpdater: TransactionHistoryUpdater(),
            transactionHistoryService: nil,
            receiveAddressService: DummyReceiveAddressService(addressInfos: []),
            sendAvailabilityProvider: TransactionSendAvailabilityProvider(hardwareLimitationsUtil: HardwareLimitationsUtil(config: config)),
            tokenBalancesRepository: TokenBalancesRepositoryMock(),
            isCustom: false
        )
        walletModel.setCryptoAccount(account)

        return walletModel
    }

    func makeJointAccount(provider: any JointAccountPendingOperationsProvider) -> any JointAccountModel {
        CommonJointAccountModel(
            cryptoAccount: CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in }),
            derivationIdentity: CryptoAccountDerivationIdentity(derivationIndex: 1, type: .joint),
            accountPolicy: JointAccountPolicy(membersCount: 2, signersCount: 2),
            accountStatus: .active(safeAddress: Self.safeAddress),
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
    private let chainIds: Set<Int>

    var pendingOperationsPublisher: AnyPublisher<[JointAccountPendingOperation], Never> {
        Just([]).eraseToAnyPublisher()
    }

    init(chainIds: Set<Int>) {
        self.chainIds = chainIds
    }

    func hasPendingOperations(chainId: Int) -> Bool {
        chainIds.contains(chainId)
    }

    func requestFrequentUpdates(operationId: String) -> AnyCancellable? {
        nil
    }
}
