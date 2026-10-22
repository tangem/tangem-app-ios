//
//  CommonJointAccountPendingOperationsProviderTests.swift
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

/// Which of the wallet's stored operations one joint account shows, and through which of its wallets.
@Suite("Tests for putting one joint account's unfinished operations together")
struct CommonJointAccountPendingOperationsProviderTests {
    /// Kept by the suite because the accounts hold it weakly.
    private let delegate = JointAccountModelDelegateMock()

    @Test("A transfer of the coin goes through the network's own wallet")
    func coinTransferGoesThroughTheCoinWallet() async throws {
        let account = makeJointAccount()
        let sut = Self.makeSUT(
            records: [Self.record(operations: [Self.coinTransfer()])],
            walletModels: [Self.makeWalletModel(tokenItem: Self.coin, account: account)]
        ).provider

        let operations = try await sut.pendingOperationsPublisher.async()
        let operation = try #require(operations.first)

        #expect(operations.count == 1)
        #expect(operation.tokenItem == Self.coin)
        #expect(operation.destination == Self.recipient)
        #expect(operation.amount?.value == 0.001)
    }

    @Test("A transfer of a token goes through the wallet at the contract, however either spells the address")
    func tokenTransferGoesThroughTheTokenWallet() async throws {
        let account = makeJointAccount()
        let sut = try Self.makeSUT(
            records: [Self.record(operations: [Self.tokenTransfer()])],
            walletModels: [
                Self.makeWalletModel(tokenItem: Self.coin, account: account),
                Self.makeWalletModel(tokenItem: Self.token, account: account),
            ]
        ).provider

        let operations = try await sut.pendingOperationsPublisher.async()
        let operation = try #require(operations.first)

        #expect(operations.count == 1)
        #expect(operation.tokenItem == Self.token)
        #expect(operation.destination == Self.recipient)
        #expect(operation.amount?.value == 5)
    }

    @Test("A fee paid in the coin is worded in the coin")
    func coinFeeIsWordedInTheCoin() async throws {
        let account = makeJointAccount()
        let sut = Self.makeSUT(
            records: [Self.record(operations: [Self.coinTransfer()])],
            walletModels: [Self.makeWalletModel(tokenItem: Self.coin, account: account)]
        ).provider

        let operations = try await sut.pendingOperationsPublisher.async()
        let operation = try #require(operations.first)

        #expect(operation.fee?.value == 0.0001)
        #expect(operation.fee?.currencySymbol == "ETH")
    }

    @Test("A fee paid in a token is worded in that token, however either spells the contract")
    func tokenFeeIsWordedInTheToken() async throws {
        let account = makeJointAccount()
        let sut = Self.makeSUT(
            records: [Self.record(operations: [Self.coinTransfer(gasToken: "0xdac17f958d2ee523a2206206994597c13d831ec7", gasPrice: 20)])],
            walletModels: [
                Self.makeWalletModel(tokenItem: Self.coin, account: account),
                Self.makeWalletModel(tokenItem: Self.token, account: account),
            ]
        ).provider

        let operations = try await sut.pendingOperationsPublisher.async()
        let operation = try #require(operations.first)

        #expect(operation.tokenItem == Self.coin)
        #expect(operation.fee?.value == 2)
        #expect(operation.fee?.currencySymbol == "USDT")
    }

    @Test("A fee in a token this wallet has not added leaves the operation in, with the fee unknown")
    func feeInATokenNotAddedIsUnknown() async throws {
        let account = makeJointAccount()
        let sut = Self.makeSUT(
            records: [Self.record(operations: [Self.coinTransfer(gasToken: "0xdac17f958d2ee523a2206206994597c13d831ec7", gasPrice: 20)])],
            walletModels: [Self.makeWalletModel(tokenItem: Self.coin, account: account)]
        ).provider

        let operations = try await sut.pendingOperationsPublisher.async()
        let operation = try #require(operations.first)

        #expect(operations.count == 1)
        #expect(operation.fee == nil)
    }

    @Test("Only the account's own record is read, whichever case its identifier is stored in")
    func onlyTheAccountsRecordIsRead() async throws {
        let account = makeJointAccount()
        let sut = Self.makeSUT(
            records: [
                Self.record(operations: [Self.coinTransfer(id: "mine")], cryptoAccountId: Self.caseFlipped(Self.cryptoAccountId)),
                Self.record(operations: [Self.coinTransfer(id: "theirs")], cryptoAccountId: String(repeating: "0", count: 64)),
            ],
            walletModels: [Self.makeWalletModel(tokenItem: Self.coin, account: account)]
        ).provider

        let operations = try await sut.pendingOperationsPublisher.async()

        #expect(operations.map(\.operation.id) == ["mine"])
    }

    @Test("An operation in a token this wallet has not added is left out until it is, the rest staying")
    func operationWithoutItsWalletIsLeftOut() async throws {
        let account = makeJointAccount()
        let sut = try Self.makeSUT(
            records: [Self.record(operations: [Self.coinTransfer(), Self.tokenTransfer()])],
            walletModels: [Self.makeWalletModel(tokenItem: Self.coin, account: account)]
        ).provider

        let operations = try await sut.pendingOperationsPublisher.async()

        #expect(operations.map(\.tokenItem) == [Self.coin])
    }

    @Test("An operation of a form this version cannot read is left out", arguments: [
        // A value along with calldata is neither of the two transfers
        (value: 1, operation: 0),
        // A delegatecall says nothing about what it does
        (value: 0, operation: 1),
    ])
    func unreadableOperationIsLeftOut(value: Int, operation: Int) async throws {
        let account = makeJointAccount()
        let calldata = try TransferERC20TokenMethod(destination: Self.recipient, amount: 5_000_000).data
        let unreadable = Self.operation(id: "unreadable", to: Self.token.contractAddress ?? "", value: BigUInt(value), data: calldata, operation: operation)
        let sut = Self.makeSUT(
            records: [Self.record(operations: [unreadable, Self.coinTransfer()])],
            walletModels: [
                Self.makeWalletModel(tokenItem: Self.coin, account: account),
                Self.makeWalletModel(tokenItem: Self.token, account: account),
            ]
        ).provider

        let operations = try await sut.pendingOperationsPublisher.async()

        #expect(operations.map(\.operation.id) == ["coin"])
    }

    @Test("A wallet no operation of a joint account goes through is left out: one without a Safe, or one of the wallet's own accounts")
    func operationThroughAnUnfitWalletIsLeftOut() async throws {
        let account = makeJointAccount()
        let withoutSafe = Self.makeWalletModel(tokenItem: Self.coin, account: account, hasSafe: false)
        let ownAccounts = Self.makeWalletModel(tokenItem: Self.coin, account: CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in }))

        for walletModel in [withoutSafe, ownAccounts] {
            let sut = Self.makeSUT(records: [Self.record(operations: [Self.coinTransfer()])], walletModels: [walletModel]).provider

            let operations = try await sut.pendingOperationsPublisher.async()

            #expect(operations.isEmpty)
        }
    }

    @Test("A token added later brings in the operation that was waiting for its wallet")
    func operationAppearsOnceItsWalletIsAdded() throws {
        let account = makeJointAccount()
        let (sut, walletModelsManager) = try Self.makeSUT(
            records: [Self.record(operations: [Self.tokenTransfer()])],
            walletModels: [Self.makeWalletModel(tokenItem: Self.coin, account: account)]
        )
        var emittedCounts: [Int] = []
        let subscription = sut.pendingOperationsPublisher.sink { emittedCounts.append($0.count) }

        walletModelsManager.walletModels.append(Self.makeWalletModel(tokenItem: Self.token, account: account))
        walletModelsManager.sendUpdate()

        #expect(emittedCounts == [0, 1])
        withExtendedLifetime(subscription) {}
    }

    @Test("The snapshot answers right away with what the publisher would emit")
    func snapshotAnswersWhatThePublisherWouldEmit() async throws {
        let account = makeJointAccount()
        let sut = try Self.makeSUT(
            records: [Self.record(operations: [Self.coinTransfer(), Self.tokenTransfer()])],
            walletModels: [
                Self.makeWalletModel(tokenItem: Self.coin, account: account),
                Self.makeWalletModel(tokenItem: Self.token, account: account),
            ]
        ).provider

        let emitted = try await sut.pendingOperationsPublisher.async()

        #expect(sut.pendingOperations == emitted)
        #expect(sut.pendingOperations.map(\.operation.id) == ["coin", "token"])
    }

    @Test("The listing dropping an operation ends it here too")
    func operationGoesWithItsRecord() throws {
        let account = makeJointAccount()
        let repository = JointAccountsRepositoryStub(pendingOperations: [Self.record(operations: [Self.coinTransfer()])])
        let sut = Self.makeSUT(repository: repository, walletModels: [Self.makeWalletModel(tokenItem: Self.coin, account: account)]).provider
        var emittedCounts: [Int] = []
        let subscription = sut.pendingOperationsPublisher.sink { emittedCounts.append($0.count) }

        repository.store(pendingOperations: [])

        #expect(emittedCounts == [1, 0])
        withExtendedLifetime(subscription) {}
    }
}

// MARK: - Helpers

private extension CommonJointAccountPendingOperationsProviderTests {
    static let userWalletId = UserWalletId(value: Data(repeating: 0xAB, count: 32))
    static let derivationIdentity = CryptoAccountDerivationIdentity(derivationIndex: 1, type: .joint)
    static let cryptoAccountId = CryptoAccountModelId(userWalletId: userWalletId, derivationIdentity: derivationIdentity).rawValue.hexString

    static let ethereum = BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil)
    static let coin: TokenItem = .blockchain(ethereum)
    static let token: TokenItem = .token(
        Token(name: "Tether", symbol: "USDT", contractAddress: "0xdAC17F958D2ee523a2206206994597C13D831ec7", decimalCount: 6),
        ethereum
    )

    static let recipient = "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c"
    static let creatorAddress = "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf"
    static let safeAddress = "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"

    static func makeSUT(
        records: [StoredJointAccountPendingOperations],
        walletModels: [any WalletModel]
    ) -> (provider: CommonJointAccountPendingOperationsProvider, walletModelsManager: WalletModelsManagerTestsMock) {
        makeSUT(repository: JointAccountsRepositoryStub(pendingOperations: records), walletModels: walletModels)
    }

    static func makeSUT(
        repository: JointAccountsRepositoryStub,
        walletModels: [any WalletModel]
    ) -> (provider: CommonJointAccountPendingOperationsProvider, walletModelsManager: WalletModelsManagerTestsMock) {
        let walletModelsManager = WalletModelsManagerTestsMock()
        walletModelsManager.walletModels = walletModels
        walletModelsManager.sendUpdate()

        let provider = CommonJointAccountPendingOperationsProvider(
            userWalletId: userWalletId,
            derivationIdentity: derivationIdentity,
            jointAccountsRepository: repository,
            walletModelsManager: walletModelsManager
        )

        return (provider, walletModelsManager)
    }

    func makeJointAccount() -> any JointAccountModel {
        CommonJointAccountModel(
            cryptoAccount: CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in }),
            derivationIdentity: Self.derivationIdentity,
            accountPolicy: JointAccountPolicy(membersCount: 2, signersCount: 2),
            accountStatus: .active(safeAddress: Self.safeAddress),
            operationsService: JointAccountOperationsServiceMock(),
            pendingOperationsProvider: JointAccountPendingOperationsProviderMock(),
            membersService: JointAccountMembersServiceMock(
                slots: [.member(JointAccountMember(name: "Isaac", address: Self.creatorAddress, role: .creator))]
            ),
            delegate: delegate
        )
    }

    static func makeWalletModel(tokenItem: TokenItem, account: any CryptoAccountModel, hasSafe: Bool = true) -> WalletModelTestsMock {
        WalletModelTestsMock(
            tokenItem: tokenItem,
            isEmpty: false,
            account: account,
            safeWalletManagerOperationsService: hasSafe ? SafeWalletManagerOperationsServiceTestsMock() : nil
        )
    }

    static func record(operations: [JointAccountOperation], cryptoAccountId: String = cryptoAccountId) -> StoredJointAccountPendingOperations {
        StoredJointAccountPendingOperations(cryptoAccountId: cryptoAccountId, operations: operations)
    }

    /// 0.001 of the coin to the recipient.
    static func coinTransfer(
        id: String = "coin",
        gasToken: String = SafeGasToken.coinGasTokenRawValue,
        gasPrice: BigUInt = 1_000_000_000
    ) -> JointAccountOperation {
        operation(id: id, to: recipient, value: 1_000_000_000_000_000, data: Data(), gasToken: gasToken, gasPrice: gasPrice)
    }

    /// 5 USDT to the recipient, worded as the contract call the Safe makes; the contract is spelled in lower case, unlike the token's.
    static func tokenTransfer(id: String = "token") throws -> JointAccountOperation {
        let calldata = try TransferERC20TokenMethod(destination: recipient, amount: 5_000_000).data

        return operation(id: id, to: "0xdac17f958d2ee523a2206206994597c13d831ec7", value: 0, data: calldata)
    }

    static func operation(
        id: String,
        to: String,
        value: BigUInt,
        data: Data,
        operation: Int = 0,
        gasToken: String = SafeGasToken.coinGasTokenRawValue,
        gasPrice: BigUInt = 1_000_000_000
    ) -> JointAccountOperation {
        JointAccountOperation(
            id: id,
            chainId: 1,
            safeTransaction: SafeTransaction(
                to: to,
                value: value,
                data: data,
                operation: operation,
                safeTxGas: 0,
                baseGas: 100_000,
                gasPrice: gasPrice,
                gasToken: gasToken,
                refundReceiver: creatorAddress,
                nonce: 0
            ),
            status: .awaitingSignatures,
            initiator: creatorAddress,
            signatures: []
        )
    }

    static func caseFlipped(_ identifier: String) -> String {
        String(identifier.map { $0.isUppercase ? Character($0.lowercased()) : Character($0.uppercased()) })
    }
}
