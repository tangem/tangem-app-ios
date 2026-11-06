//
//  JointAccountsNotificationBadgeCounterTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("Joint accounts notification badge counter")
struct JointAccountsNotificationBadgeCounterTests {
    private let delegate = JointAccountModelDelegateMock()

    @Test("A wallet without joint accounts counts zero")
    func noJointAccountsCountZero() {
        let published = record(JointAccountsNotificationBadgeCounter(accountModelsManager: AccountModelsManagerStub(accounts: []))) {}

        #expect(published == [0])
    }

    @Test("Only the operations the user can still sign are counted")
    func onlySignableOperationsAreCounted() throws {
        let account = makeAccount()

        try account.provider.send([
            makeOperation(in: account.model, id: "unanswered", signatures: [Self.creatorSignature]),
            makeOperation(in: account.model, id: "signed", signatures: [Self.creatorSignature, Self.ownSignature(.signed)]),
            makeOperation(in: account.model, id: "declined", signatures: [Self.creatorSignature, Self.ownSignature(.declined)]),
            makeOperation(in: account.model, id: "own", initiator: Constants.ownAddress, signatures: [Self.ownSignature(.signed)]),
            makeOperation(in: account.model, id: "executing", status: .pending, signatures: [Self.creatorSignature]),
        ])

        let published = record(makeCounter(accounts: [account.model])) {}

        #expect(published == [1])
    }

    @Test("An account the user is not a member of counts nothing")
    func accountWithoutOwnMembershipCountsNothing() throws {
        let account = makeAccount(isMember: false)
        try account.provider.send([makeOperation(in: account.model, signatures: [Self.creatorSignature])])

        let published = record(makeCounter(accounts: [account.model])) {}

        #expect(published == [0])
    }

    @Test("Counts of several joint accounts add up")
    func countsOfAccountsAddUp() throws {
        let first = makeAccount(derivationIndex: 1)
        let second = makeAccount(derivationIndex: 2)
        try first.provider.send([makeOperation(in: first.model, signatures: [Self.creatorSignature])])
        try second.provider.send([
            makeOperation(in: second.model, id: "first", signatures: [Self.creatorSignature]),
            makeOperation(in: second.model, id: "second", signatures: [Self.creatorSignature]),
        ])

        let published = record(makeCounter(accounts: [first.model, second.model])) {}

        #expect(published == [3])
    }

    @Test("The count follows the account's operations and its members")
    func countFollowsOperationsAndMembers() throws {
        let account = makeAccount()
        let signable = try makeOperation(in: account.model, signatures: [Self.creatorSignature])

        let published = record(makeCounter(accounts: [account.model])) {
            account.provider.send([signable])
            account.members.send(isMember: false)
            account.members.send(isMember: true)
            account.provider.send([])
        }

        #expect(published == [0, 1, 0, 1, 0])
    }
}

// MARK: - Helpers

private extension JointAccountsNotificationBadgeCounterTests {
    typealias Account = (model: any JointAccountModel, provider: PendingOperationsProviderStub, members: MembersServiceStub)

    static let creatorSignature = JointAccountOperation.Signature(address: Constants.creatorAddress, state: .signed, at: Constants.signedAt)

    static func ownSignature(_ state: JointAccountOperation.Signature.State) -> JointAccountOperation.Signature {
        JointAccountOperation.Signature(address: Constants.ownAddress, state: state, at: Constants.signedAt)
    }

    func makeCounter(accounts: [any JointAccountModel]) -> JointAccountsNotificationBadgeCounter {
        JointAccountsNotificationBadgeCounter(accountModelsManager: AccountModelsManagerStub(accounts: [.joint(accounts)]))
    }

    func makeAccount(derivationIndex: Int = 1, isMember: Bool = true) -> Account {
        let provider = PendingOperationsProviderStub()
        let members = MembersServiceStub(isMember: isMember)

        let model = CommonJointAccountModel(
            cryptoAccount: CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in }),
            derivationIdentity: CryptoAccountDerivationIdentity(derivationIndex: derivationIndex, type: .joint),
            accountPolicy: JointAccountPolicy(membersCount: 2, signersCount: 2),
            statusProvider: JointAccountStatusProviderStub(status: .active(safeAddress: Constants.safeAddress)),
            operationsService: JointAccountOperationsServiceMock(),
            pendingOperationsProvider: provider,
            membersService: members,
            finishedOperationsWalletUpdater: JointAccountFinishedOperationsWalletUpdater(
                pendingOperationsProvider: JointAccountPendingOperationsProviderMock(),
                walletModelsManager: WalletModelsManagerMock(),
                historyDeltaSyncing: JointOperationsHistoryDeltaSyncingStub()
            ),
            userRoleService: JointAccountUserRoleServiceMock(address: Constants.ownAddress),
            delegate: delegate
        )

        return (model, provider, members)
    }

    func makeOperation(
        in account: any JointAccountModel,
        id: String = "coin",
        status: JointAccountOperationStatus = .awaitingSignatures,
        initiator: String = Constants.creatorAddress,
        signatures: [JointAccountOperation.Signature]
    ) throws -> JointAccountPendingOperation {
        let wallet = try JointAccountWalletBuilder().build(
            walletModel: WalletModelTestsMock(
                tokenItem: Constants.coin,
                isEmpty: false,
                account: account,
                safeWalletManagerOperationsService: SafeWalletManagerOperationsServiceTestsMock()
            )
        )

        let operation = JointAccountCompositionFixture.coinTransfer(id: id, status: status, initiator: initiator, signatures: signatures)

        let operationInitiator: JointAccountPendingOperation.Initiator = initiator.caseInsensitiveEquals(to: Constants.ownAddress)
            ? .me
            : .unlisted(address: initiator)

        return JointAccountPendingOperation(
            wallet: wallet,
            initiator: operationInitiator,
            operation: operation,
            operationPublisher: Just(operation).eraseToAnyPublisher(),
            innerCallType: .transfer(.coin(destination: Constants.recipient, value: 1_000_000_000_000_000)),
            feeTokenItem: Constants.coin
        )
    }

    func record(_ counter: JointAccountsNotificationBadgeCounter, actions: () -> Void) -> [Int] {
        var published: [Int] = []
        let subscription = counter.notificationBadgeCountPublisher.sink { published.append($0) }

        actions()
        subscription.cancel()

        return published
    }

    enum Constants {
        static let coin: TokenItem = .blockchain(BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil))
        static let recipient = "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c"
        static let safeAddress = "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"
        static let creatorAddress = "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf"
        static let ownAddress = "0x3c9e1b7a5d2f80461c8a0e2b4d6f8a0c2e4b6c90"
        static let signedAt = "2026-10-27T10:00:00Z"
    }
}

// MARK: - Stubs

private final class PendingOperationsProviderStub: JointAccountPendingOperationsProvider {
    private let operationsSubject = CurrentValueSubject<[JointAccountPendingOperation], Never>([])

    var pendingOperationsPublisher: AnyPublisher<[JointAccountPendingOperation], Never> {
        operationsSubject.eraseToAnyPublisher()
    }

    func hasPendingOperations(chainId: Int) -> Bool {
        false
    }

    func requestFrequentUpdates(operationId: String) -> AnyCancellable? {
        nil
    }

    func loadOperation(id: String) async throws -> JointAccountPendingOperation {
        throw "Not called by these tests"
    }

    func send(_ operations: [JointAccountPendingOperation]) {
        operationsSubject.send(operations)
    }
}

private final class MembersServiceStub: JointAccountMembersService {
    private let slotsSubject: CurrentValueSubject<[JointAccountSlot], Never>

    init(isMember: Bool) {
        slotsSubject = CurrentValueSubject(Self.slots(isMember: isMember))
    }

    var slotsPublisher: AnyPublisher<[JointAccountSlot], Never> {
        slotsSubject.eraseToAnyPublisher()
    }

    func requestFrequentUpdates() -> AnyCancellable {
        AnyCancellable {}
    }

    func issueInvite(slot: JointAccountMemberSlotID) async throws(JointAccountInviteIssueError) -> JointAccountInvite {
        throw .failed(CancellationError())
    }

    func send(isMember: Bool) {
        slotsSubject.send(Self.slots(isMember: isMember))
    }

    private static func slots(isMember: Bool) -> [JointAccountSlot] {
        let creator = JointAccountMember(
            name: "Creator",
            address: "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf",
            role: .creator,
            isMe: false,
            signature: nil
        )
        let member = JointAccountMember(
            name: "Member",
            address: "0x3c9e1b7a5d2f80461c8a0e2b4d6f8a0c2e4b6c90",
            role: .member,
            isMe: isMember,
            signature: nil
        )

        return [.member(creator, .active), .member(member, .active)]
    }
}
