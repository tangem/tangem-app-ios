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

        operationSubject.send(JointAccountCompositionFixture.coinTransfer(status: .executed))

        #expect(statuses.received.count == 2)
        #expect(statuses.received.first == .awaitingSignatures)
        #expect(statuses.received.last?.isSent == true)
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

    enum Constants {
        static let coin: TokenItem = .blockchain(BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil))
        static let recipient = "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c"
        static let safeAddress = "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"
    }
}

private extension JointAccountOperationDetailsViewModel.Status {
    var isSent: Bool {
        if case .sent = self {
            return true
        }

        return false
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

private final class PendingOperationsProviderStub: JointAccountPendingOperationsProvider {
    var pendingOperations: [JointAccountPendingOperation] { [] }

    var pendingOperationsPublisher: AnyPublisher<[JointAccountPendingOperation], Never> {
        Empty().eraseToAnyPublisher()
    }

    func requestFrequentUpdates(operationId: String) -> AnyCancellable? {
        nil
    }
}
