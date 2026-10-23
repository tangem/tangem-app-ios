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
import BigInt
import TangemFoundation
@testable import Tangem

// MARK: - Tests

@Suite("Tests for a joint account's unfinished operations counting as pending transactions of its wallets")
struct WalletModelJointAccountPendingTransactionsTests {
    private let delegate = JointAccountModelDelegateMock()

    @Test("An operation underway in this token is a pending transaction of the token and of its network", arguments: [
        JointAccountOperationStatus.awaitingSignatures,
        .pending,
    ])
    func operationUnderwayInThisTokenCounts(status: JointAccountOperationStatus) throws {
        let provider = PendingOperationsProviderStub()
        let account = makeJointAccount(provider: provider)
        provider.pendingOperations = try [Self.operation(status: status, in: Self.coin, of: account)]
        let sut = Self.makeWalletModel(account: account)

        #expect(sut.hasPendingTransactions)
        #expect(sut.hasAnyPendingTransactions)
    }

    @Test("An operation underway in another token of the network is a pending transaction of the network alone")
    func operationUnderwayInAnotherTokenCountsForTheNetworkAlone() throws {
        let provider = PendingOperationsProviderStub()
        let account = makeJointAccount(provider: provider)
        provider.pendingOperations = try [Self.operation(status: .awaitingSignatures, in: Self.token, of: account)]
        let sut = Self.makeWalletModel(account: account)

        #expect(!sut.hasPendingTransactions)
        #expect(sut.hasAnyPendingTransactions)
    }

    @Test("An operation that is over is no pending transaction", arguments: [
        JointAccountOperationStatus.executed,
        .failed,
        .cancelled,
        .unknown,
    ])
    func operationThatIsOverDoesNotCount(status: JointAccountOperationStatus) throws {
        let provider = PendingOperationsProviderStub()
        let account = makeJointAccount(provider: provider)
        provider.pendingOperations = try [Self.operation(status: status, in: Self.coin, of: account)]
        let sut = Self.makeWalletModel(account: account)

        #expect(!sut.hasPendingTransactions)
        #expect(!sut.hasAnyPendingTransactions)
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
    static let token: TokenItem = .token(
        Token(name: "Tether", symbol: "USDT", contractAddress: "0xdAC17F958D2ee523a2206206994597C13D831ec7", decimalCount: 6),
        ethereum
    )

    static let recipient = "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c"
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
                slots: [.member(JointAccountMember(name: "Isaac", address: Self.creatorAddress, role: .creator))]
            ),
            delegate: delegate
        )
    }

    static func operation(
        status: JointAccountOperationStatus,
        in tokenItem: TokenItem,
        of account: any JointAccountModel
    ) throws -> JointAccountPendingOperation {
        let wallet = try JointAccountWalletBuilder().build(
            walletModel: WalletModelTestsMock(
                tokenItem: tokenItem,
                isEmpty: false,
                account: account,
                safeWalletManagerOperationsService: SafeWalletManagerOperationsServiceTestsMock()
            )
        )

        let innerCallType: SafeInnerCallType = if let contractAddress = tokenItem.contractAddress {
            .transfer(.token(contractAddress: contractAddress, destination: recipient, value: 5_000_000))
        } else {
            .transfer(.coin(destination: recipient, value: 1_000_000_000_000_000))
        }

        return JointAccountPendingOperation(
            wallet: wallet,
            operation: JointAccountCompositionFixture.coinTransfer(status: status),
            innerCallType: innerCallType,
            feeTokenItem: .blockchain(tokenItem.blockchainNetwork)
        )
    }
}

// MARK: - Stubs

private final class PendingOperationsProviderStub: JointAccountPendingOperationsProvider {
    var pendingOperations: [JointAccountPendingOperation] = []

    var pendingOperationsPublisher: AnyPublisher<[JointAccountPendingOperation], Never> {
        Just(pendingOperations).eraseToAnyPublisher()
    }

    func requestFrequentUpdates() -> AnyCancellable {
        AnyCancellable {}
    }
}
