//
//  JointAccountOperationDetailsViewModelBuilderTests.swift
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

@Suite("Tests for the operation details content following the pending operations listing")
struct JointAccountOperationDetailsViewModelBuilderTests {
    private let provider = PendingOperationsProviderStub()
    private let delegate = JointAccountModelDelegateMock()

    @Test("An operation the poller reports as executed is shown as sent")
    func executedOperationIsShownAsSent() throws {
        let operationSubject = Self.makeOperationSubject(status: .awaitingSignatures)
        let operation = try makePendingOperation(operationSubject: operationSubject)
        let statuses = StatusesCollector(following: operation)

        operationSubject.send(JointAccountCompositionFixture.coinTransfer(status: .executed, finishedAt: Constants.finishedAt))

        #expect(statuses.received == [.awaitingSignatures, .sent(at: Constants.finishedAt)])
    }

    @Test("An operation the poller reports as failed is shown as failed")
    func failedOperationIsShownAsFailed() throws {
        let operationSubject = Self.makeOperationSubject(status: .awaitingSignatures)
        let operation = try makePendingOperation(operationSubject: operationSubject)
        let statuses = StatusesCollector(following: operation)

        operationSubject.send(JointAccountCompositionFixture.coinTransfer(status: .failed, finishedAt: Constants.finishedAt))

        #expect(statuses.received == [.awaitingSignatures, .failed(at: Constants.finishedAt)])
    }

    @Test(
        "An operation called off, or at a stage this version does not know, is shown as cancelled",
        arguments: [JointAccountOperationStatus.cancelled, .unknown]
    )
    func finishedOperationIsShownAsCancelled(status: JointAccountOperationStatus) throws {
        let operationSubject = Self.makeOperationSubject(status: .awaitingSignatures)
        let operation = try makePendingOperation(operationSubject: operationSubject)
        let statuses = StatusesCollector(following: operation)

        operationSubject.send(JointAccountCompositionFixture.coinTransfer(status: status, finishedAt: Constants.finishedAt))

        #expect(statuses.received == [.awaitingSignatures, .cancelled(at: Constants.finishedAt)])
    }

    @Test("An operation the relayer took over is shown as sending")
    func pendingOperationIsShownAsSending() throws {
        let operationSubject = Self.makeOperationSubject(status: .awaitingSignatures)
        let operation = try makePendingOperation(operationSubject: operationSubject)
        let statuses = StatusesCollector(following: operation)

        operationSubject.send(JointAccountCompositionFixture.coinTransfer(status: .pending))

        #expect(statuses.received == [.awaitingSignatures, .sending])
    }

    @Test("An operation reported unchanged does not redraw the sheet")
    func unchangedOperationIsNotRepeated() throws {
        let operationSubject = Self.makeOperationSubject(status: .awaitingSignatures)
        let operation = try makePendingOperation(operationSubject: operationSubject)
        let statuses = StatusesCollector(following: operation)

        operationSubject.send(JointAccountCompositionFixture.coinTransfer(status: .awaitingSignatures))

        #expect(statuses.received == [.awaitingSignatures])
    }

    @Test("The recipient is offered for contacts only once the address book is synced", .timeLimit(.minutes(1)))
    func recipientIsOfferedOnceTheBookIsSynced() async throws {
        let operation = try makePendingOperation(operationSubject: Self.makeOperationSubject(status: .awaitingSignatures))
        let syncState = CurrentValueSubject<AddressBookSyncState, Never>(.syncing)
        let collector = RecipientStatesCollector(following: operation, contacts: Just([]), syncState: syncState)
        var states = collector.states.makeAsyncIterator()

        #expect(await states.next()?.canAddToContacts == false)

        syncState.send(.synced)

        #expect(await states.next()?.canAddToContacts == true)
    }

    @Test("A recipient saved in this wallet's book on the operation's network is no longer offered", .timeLimit(.minutes(1)))
    func savedRecipientIsNotOffered() async throws {
        let operation = try makePendingOperation(operationSubject: Self.makeOperationSubject(status: .awaitingSignatures))
        let contacts = CurrentValueSubject<[AddressBookContact], Never>([])
        let collector = RecipientStatesCollector(following: operation, contacts: contacts, syncState: Just(.synced))
        var states = collector.states.makeAsyncIterator()

        #expect(await states.next()?.canAddToContacts == true)

        try contacts.send([makeContact(walletId: Constants.userWalletId, address: Constants.recipient)])

        #expect(await states.next()?.canAddToContacts == false)
    }

    @Test("A recipient saved only in another wallet's book is named after it and still offered", .timeLimit(.minutes(1)))
    func recipientSavedInAnotherWalletIsOffered() async throws {
        let operation = try makePendingOperation(operationSubject: Self.makeOperationSubject(status: .awaitingSignatures))
        let otherWalletId = UserWalletId(value: Data(repeating: 0xCD, count: 32))
        let contacts = try [makeContact(walletId: otherWalletId, address: Constants.recipient)]
        let collector = RecipientStatesCollector(following: operation, contacts: Just(contacts), syncState: Just(.synced))
        var states = collector.states.makeAsyncIterator()

        let state = try #require(await states.next())
        #expect(state.canAddToContacts)
        #expect(state.owner.contactName == "Alice")
    }
}

// MARK: - Fixtures

private extension JointAccountOperationDetailsViewModelBuilderTests {
    static func makeOperationSubject(status: JointAccountOperationStatus) -> CurrentValueSubject<JointAccountOperation, Never> {
        CurrentValueSubject(JointAccountCompositionFixture.coinTransfer(status: status))
    }

    func makePendingOperation(operationSubject: CurrentValueSubject<JointAccountOperation, Never>) throws -> JointAccountPendingOperation {
        let account = CommonJointAccountModel(
            cryptoAccount: CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in }),
            derivationIdentity: JointAccountCompositionFixture.derivationIdentity,
            accountPolicy: JointAccountPolicy(membersCount: 2, signersCount: 2),
            accountStatus: .active(safeAddress: Constants.safeAddress),
            operationsService: JointAccountOperationsServiceMock(),
            pendingOperationsProvider: provider,
            membersService: JointAccountMembersServiceMock(slots: []),
            delegate: delegate
        )

        let wallet = try JointAccountWalletBuilder().build(
            walletModel: WalletModelTestsMock(
                tokenItem: Constants.coin,
                isEmpty: false,
                account: account,
                safeWalletManagerOperationsService: SafeWalletManagerOperationsServiceTestsMock()
            )
        )

        return JointAccountPendingOperation(
            wallet: wallet,
            operation: operationSubject.value,
            operationPublisher: operationSubject.removeDuplicates().eraseToAnyPublisher(),
            innerCallType: .transfer(.coin(destination: Constants.recipient, value: 1_000_000_000_000_000)),
            feeTokenItem: Constants.coin
        )
    }

    func makeContact(walletId: UserWalletId, address: String) throws -> AddressBookContact {
        let blockchain = Constants.coin.blockchain
        let contactId = AddressBookContactID()
        let contactName = try AddressBookContactNameValidator().validate("Alice")

        let decoded = AddressBookDecodedAddressEntry(
            id: AddressBookAddressEntryID(),
            address: address,
            networkId: AddressBookNetworkID(blockchain.networkId),
            memo: nil,
            signature: Data([0x01])
        )

        let built = AddressBookVerifiedAddressEntryBuilder(supportedBlockchains: [blockchain]).make(
            verifying: decoded,
            contactId: contactId,
            contactName: contactName,
            walletPublicKey: Data(repeating: 0xB2, count: 33),
            verifier: AddressBookSignatureVerifyingStub()
        )

        let verified = try #require(built)
        let entries = try #require(AddressBookContactVerifiedEntries([verified]))

        return AddressBookContact(
            id: contactId,
            walletId: walletId,
            name: contactName,
            appearance: AddressBookContactAppearance(rawColor: "MexicanPink"),
            createdAt: Date(),
            entries: entries
        )
    }

    enum Constants {
        static let userWalletId = UserWalletId(value: Data(repeating: 0xAB, count: 32))
        static let coin: TokenItem = .blockchain(BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil))
        static let recipient = "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c"
        static let safeAddress = "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"
        static let finishedAt = Date(timeIntervalSince1970: 1_791_379_800)
    }
}

private extension TransactionViewModel.SubtitleOwner {
    var contactName: String? {
        if case .contact(let name, _, _) = self {
            return name
        }

        return nil
    }
}

// MARK: - Stubs

private final class StatusesCollector {
    private let statuses = OSAllocatedUnfairLock(initialState: [JointAccountOperationDetailsViewModel.Status]())
    private var subscription: AnyCancellable?

    init(following operation: JointAccountPendingOperation) {
        subscription = JointAccountOperationDetailsViewModelBuilder()
            .contentPublisher(of: operation)
            .sink { [statuses] content in
                statuses.withLock { $0.append(content.status) }
            }
    }

    var received: [JointAccountOperationDetailsViewModel.Status] {
        statuses.withLock { $0 }
    }
}

private final class RecipientStatesCollector {
    let states: AsyncStream<JointAccountOperationDetailsViewModel.RecipientState>
    private var subscription: AnyCancellable?

    init(
        following operation: JointAccountPendingOperation,
        contacts: some Publisher<[AddressBookContact], Never>,
        syncState: some Publisher<AddressBookSyncState, Never>
    ) {
        let (states, continuation) = AsyncStream<JointAccountOperationDetailsViewModel.RecipientState>.makeStream()
        self.states = states

        subscription = JointAccountOperationDetailsViewModelBuilder()
            .recipientStatePublisher(
                of: operation,
                userWalletId: JointAccountOperationDetailsViewModelBuilderTests.Constants.userWalletId,
                contactsPublisher: contacts,
                syncStatePublisher: syncState,
                tangemPayDepositOwnersPublisher: Just([])
            )
            .sink { state in
                continuation.yield(state)
            }
    }
}

private struct AddressBookSignatureVerifyingStub: AddressBookSignatureVerifying {
    func isSignatureValid(_ signature: Data, of digest: Data, walletPublicKey: Data) -> Bool {
        true
    }
}

private final class PendingOperationsProviderStub: JointAccountPendingOperationsProvider {
    var pendingOperations: [JointAccountPendingOperation] { [] }

    var pendingOperationsPublisher: AnyPublisher<[JointAccountPendingOperation], Never> {
        Empty().eraseToAnyPublisher()
    }

    func requestFrequentUpdates(operationId: String) -> AnyCancellable? {
        nil
    }
}
