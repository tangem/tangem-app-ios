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

        #expect(operations.map(\.id) == ["mine"])
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

        #expect(operations.map(\.id) == ["coin"])
    }

    @Test("An operation aimed at the Safe itself is left out")
    func operationAimedAtTheSafeIsLeftOut() async throws {
        let account = makeJointAccount()
        let toSafe = Self.operation(id: "to-safe", to: Self.safeAddress, value: 1, data: Data())
        let sut = Self.makeSUT(
            records: [Self.record(operations: [toSafe, Self.coinTransfer()])],
            walletModels: [Self.makeWalletModel(tokenItem: Self.coin, account: account)]
        ).provider

        let operations = try await sut.pendingOperationsPublisher.async()

        #expect(operations.map(\.id) == ["coin"])
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

    // MARK: - Networks in use

    @Test("An operation in flight holds its network and no other", arguments: [JointAccountOperationStatus.awaitingSignatures, .pending])
    func operationInFlightHoldsItsNetwork(status: JointAccountOperationStatus) throws {
        let sut = Self.makeSUT(records: [Self.record(operations: [Self.coinTransfer(status: status)])], walletModels: []).provider

        #expect(try sut.hasPendingOperations(chainId: #require(Self.coin.blockchain.chainId)))
        #expect(try !sut.hasPendingOperations(chainId: #require(Blockchain.polygon(testnet: false).chainId)))
    }

    @Test(
        "An operation that is over holds no network, though the store keeps it",
        arguments: [JointAccountOperationStatus.executed, .failed, .cancelled, .unknown]
    )
    func operationThatIsOverHoldsNoNetwork(status: JointAccountOperationStatus) throws {
        let sut = Self.makeSUT(records: [Self.record(operations: [Self.coinTransfer(status: status)])], walletModels: []).provider

        #expect(try !sut.hasPendingOperations(chainId: #require(Self.coin.blockchain.chainId)))
    }

    @Test("An operation in a token this device has not added holds the network all the same")
    func operationInAMissingTokenHoldsTheNetwork() throws {
        let account = makeJointAccount()
        let sut = try Self.makeSUT(
            records: [Self.record(operations: [Self.tokenTransfer()])],
            walletModels: [Self.makeWalletModel(tokenItem: Self.coin, account: account)]
        ).provider

        #expect(try sut.hasPendingOperations(chainId: #require(Self.coin.blockchain.chainId)))
    }

    @Test("An operation of another account holds none of this account's networks")
    func operationOfAnotherAccountHoldsNoNetwork() throws {
        let sut = Self.makeSUT(
            records: [Self.record(operations: [Self.coinTransfer()], cryptoAccountId: String(repeating: "0", count: 64))],
            walletModels: []
        ).provider

        #expect(try !sut.hasPendingOperations(chainId: #require(Self.coin.blockchain.chainId)))
    }

    // MARK: - Initiator

    @Test("An operation this wallet made is its own")
    func ownOperationIsMine() async throws {
        let account = makeJointAccount(ownAddress: Self.ownAddress)
        let sut = Self.makeSUT(
            records: [Self.record(operations: [Self.coinTransfer(initiator: Self.ownAddress.uppercased())])],
            walletModels: [Self.makeWalletModel(tokenItem: Self.coin, account: account)]
        ).provider

        let operation = try #require(try await sut.pendingOperationsPublisher.async().first)

        #expect(operation.initiator == .me)
    }

    @Test("An operation another member made is named after them")
    func memberOperationIsNamed() async throws {
        let account = makeJointAccount(ownAddress: Self.ownAddress)
        let sut = Self.makeSUT(
            records: [Self.record(operations: [Self.coinTransfer(initiator: Self.creatorAddress.uppercased())])],
            walletModels: [Self.makeWalletModel(tokenItem: Self.coin, account: account)]
        ).provider

        let operation = try #require(try await sut.pendingOperationsPublisher.async().first)

        #expect(operation.initiator == .member(name: Self.creator.name))
    }

    @Test("An operation of a member the account no longer lists is told by its address")
    func unlistedOperationKeepsTheAddress() async throws {
        let account = makeJointAccount(ownAddress: Self.ownAddress)
        let sut = Self.makeSUT(
            records: [Self.record(operations: [Self.coinTransfer()])],
            walletModels: [Self.makeWalletModel(tokenItem: Self.coin, account: account)],
            members: []
        ).provider

        let operation = try #require(try await sut.pendingOperationsPublisher.async().first)

        #expect(operation.initiator == .unlisted(address: Self.creatorAddress))
    }

    @Test("Only the operations in flight are listed, though the store keeps the finished ones")
    func onlyOperationsInFlightAreListed() async throws {
        let account = makeJointAccount()
        let sut = Self.makeSUT(
            records: [Self.record(operations: [Self.coinTransfer(), Self.coinTransfer(id: "executed", status: .executed)])],
            walletModels: [Self.makeWalletModel(tokenItem: Self.coin, account: account)]
        ).provider

        let operations = try await sut.pendingOperationsPublisher.async()

        #expect(operations.map(\.id) == ["coin"])
    }

    @Test("An operation loaded by its id is asked of the repository under the account and goes through the account's wallet")
    func loadedOperationGoesThroughTheAccountsWallet() async throws {
        let account = makeJointAccount()
        let loaded = Self.coinTransfer(id: "loaded", status: .failed)
        let repository = JointAccountPendingOperationsRepositoryStub(loadedOperationAnswer: .success(loaded))
        let sut = Self.makeSUT(repository: repository, walletModels: [Self.makeWalletModel(tokenItem: Self.coin, account: account)]).provider

        let operation = try await sut.loadOperation(id: "loaded")

        #expect(operation.id == loaded.id)
        #expect(operation.status == loaded.status)
        #expect(operation.tokenItem == Self.coin)
        #expect(repository.loadedOperations.map(\.id) == ["loaded"])
        #expect(repository.loadedOperations.map(\.cryptoAccountId) == [Self.cryptoAccountId])
    }

    @Test("An operation loaded by its id in a token this wallet has not added cannot be shown")
    func loadedOperationWithoutItsWalletIsReported() async throws {
        let account = makeJointAccount()
        let repository = try JointAccountPendingOperationsRepositoryStub(loadedOperationAnswer: .success(Self.tokenTransfer()))
        let sut = Self.makeSUT(repository: repository, walletModels: [Self.makeWalletModel(tokenItem: Self.coin, account: account)]).provider

        await #expect(throws: JointAccountPendingOperationsProviderError.walletNotFound) {
            try await sut.loadOperation(id: "token")
        }
    }

    @Test("Each operation is followed through the store to its end, and falls silent once the store drops it")
    func operationIsFollowedToItsEnd() async throws {
        let account = makeJointAccount()
        let repository = JointAccountPendingOperationsRepositoryStub(pendingOperations: [Self.record(operations: [Self.coinTransfer()])])
        let sut = Self.makeSUT(repository: repository, walletModels: [Self.makeWalletModel(tokenItem: Self.coin, account: account)]).provider
        let operation = try #require(try await sut.pendingOperationsPublisher.async().first)
        var statuses: [JointAccountOperationStatus] = []
        let subscription = operation.didChangePublisher.sink { statuses.append($0.status) }

        repository.store(pendingOperations: [Self.record(operations: [Self.coinTransfer(status: .pending)])])
        repository.store(pendingOperations: [Self.record(operations: [Self.coinTransfer(status: .executed)])])
        repository.store(pendingOperations: [])

        #expect(statuses == [.awaitingSignatures, .pending, .executed])
        withExtendedLifetime(subscription) {}
    }

    @Test("An operation of another account is not taken for this one, whatever its identifier")
    func operationOfAnotherAccountIsNotFollowed() async throws {
        let account = makeJointAccount()
        let repository = JointAccountPendingOperationsRepositoryStub(pendingOperations: [Self.record(operations: [Self.coinTransfer()])])
        let sut = Self.makeSUT(repository: repository, walletModels: [Self.makeWalletModel(tokenItem: Self.coin, account: account)]).provider
        let operation = try #require(try await sut.pendingOperationsPublisher.async().first)
        var statuses: [JointAccountOperationStatus] = []
        let subscription = operation.didChangePublisher.sink { statuses.append($0.status) }

        repository.store(pendingOperations: [
            Self.record(operations: [Self.coinTransfer(status: .executed)], cryptoAccountId: String(repeating: "0", count: 64)),
        ])

        #expect(statuses == [.awaitingSignatures])
        withExtendedLifetime(subscription) {}
    }

    @Test("Frequent updates of an operation are asked of the repository, and given back with it")
    func frequentUpdatesAreAskedOfTheRepository() throws {
        let repository = JointAccountPendingOperationsRepositoryStub()
        let sut = Self.makeSUT(repository: repository, walletModels: []).provider

        let subscription = try #require(sut.requestFrequentUpdates(operationId: "coin"))
        let countWhileRequested = repository.frequentUpdatesRequestsCount(operationId: "coin")
        subscription.cancel()

        #expect(countWhileRequested == 1)
        #expect(repository.frequentUpdatesRequestsCount(operationId: "coin") == 0)
    }

    @Test("The listing dropping an operation ends it here too")
    func operationGoesWithItsRecord() throws {
        let account = makeJointAccount()
        let repository = JointAccountPendingOperationsRepositoryStub(pendingOperations: [Self.record(operations: [Self.coinTransfer()])])
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
    static let ownAddress = "0x3c9e1b7a5d2f80461c8a0e2b4d6f8a0c2e4b6c90"
    static let creator = JointAccountMember(name: "Isaac", address: creatorAddress, role: .creator, isMe: false, signature: nil)
    static let safeAddress = "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"

    static func makeSUT(
        records: [StoredJointAccountPendingOperations],
        walletModels: [any WalletModel],
        members: [JointAccountMember] = [creator]
    ) -> (provider: CommonJointAccountPendingOperationsProvider, walletModelsManager: WalletModelsManagerTestsMock) {
        let repository = JointAccountPendingOperationsRepositoryStub(pendingOperations: records)

        return makeSUT(repository: repository, walletModels: walletModels, members: members)
    }

    static func makeSUT(
        repository: JointAccountPendingOperationsRepositoryStub,
        walletModels: [any WalletModel],
        members: [JointAccountMember] = [creator]
    ) -> (provider: CommonJointAccountPendingOperationsProvider, walletModelsManager: WalletModelsManagerTestsMock) {
        let walletModelsManager = WalletModelsManagerTestsMock()
        walletModelsManager.walletModels = walletModels
        walletModelsManager.sendUpdate()

        let provider = CommonJointAccountPendingOperationsProvider(
            userWalletId: userWalletId,
            derivationIdentity: derivationIdentity,
            pendingOperationsRepository: repository,
            walletModelsManager: walletModelsManager,
            membersService: JointAccountMembersServiceMock(slots: members.map { .member($0, .active) })
        )

        return (provider, walletModelsManager)
    }

    func makeJointAccount(ownAddress: String? = nil) -> any JointAccountModel {
        CommonJointAccountModel(
            cryptoAccount: CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in }),
            derivationIdentity: Self.derivationIdentity,
            accountPolicy: JointAccountPolicy(membersCount: 2, signersCount: 2),
            statusProvider: JointAccountStatusProviderStub(status: .active(safeAddress: Self.safeAddress)),
            operationsService: JointAccountOperationsServiceMock(),
            pendingOperationsProvider: JointAccountPendingOperationsProviderMock(),
            membersService: JointAccountMembersServiceMock(
                slots: [.member(Self.creator, .active)]
            ),
            finishedOperationsWalletUpdater: JointAccountFinishedOperationsWalletUpdater(
                pendingOperationsProvider: JointAccountPendingOperationsProviderMock(),
                walletModelsManager: WalletModelsManagerMock(),
                historyDeltaSyncing: JointOperationsHistoryDeltaSyncingStub()
            ),
            userRoleService: JointAccountUserRoleServiceMock(address: ownAddress),
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
        status: JointAccountOperationStatus = .awaitingSignatures,
        gasToken: String = SafeGasToken.coinGasTokenRawValue,
        gasPrice: BigUInt = 1_000_000_000,
        initiator: String = creatorAddress
    ) -> JointAccountOperation {
        operation(
            id: id,
            to: recipient,
            value: 1_000_000_000_000_000,
            data: Data(),
            status: status,
            gasToken: gasToken,
            gasPrice: gasPrice,
            initiator: initiator
        )
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
        status: JointAccountOperationStatus = .awaitingSignatures,
        gasToken: String = SafeGasToken.coinGasTokenRawValue,
        gasPrice: BigUInt = 1_000_000_000,
        initiator: String = creatorAddress
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
            status: status,
            txHash: nil,
            finishedAt: nil,
            cancelReason: nil,
            initiator: initiator,
            signatures: [],
            createdAt: nil,
            threshold: nil
        )
    }

    static func caseFlipped(_ identifier: String) -> String {
        String(identifier.map { $0.isUppercase ? Character($0.lowercased()) : Character($0.uppercased()) })
    }
}
