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

    @Test("An operation that leaves the listing leaves the sheet as it was")
    func operationLeavingTheListingChangesNothing() throws {
        let operation = try makePendingOperation(status: .awaitingSignatures)
        let statuses = StatusesCollector(following: operation, provider: provider)

        provider.listing.send([operation])
        provider.listing.send([])

        #expect(statuses.received == [.awaitingSignatures])
    }

    @Test("An operation the listing reports as executed is shown as sent")
    func executedOperationIsShownAsSent() throws {
        let operation = try makePendingOperation(status: .awaitingSignatures)
        let executed = try makePendingOperation(status: .executed)
        let statuses = StatusesCollector(following: operation, provider: provider)

        provider.listing.send([operation])
        provider.listing.send([executed])

        #expect(statuses.received.count == 2)
        #expect(statuses.received.first == .awaitingSignatures)
        #expect(statuses.received.last?.isSent == true)
    }

    @Test("An operation the relayer took over is shown as sending while it stays listed")
    func pendingOperationIsShownAsSending() throws {
        let operation = try makePendingOperation(status: .awaitingSignatures)
        let executing = try makePendingOperation(status: .pending)
        let statuses = StatusesCollector(following: operation, provider: provider)

        provider.listing.send([operation])
        provider.listing.send([executing])

        #expect(statuses.received == [.awaitingSignatures, .sending])
    }

    @Test("A listing that still carries the operation unchanged does not redraw the sheet")
    func unchangedListingIsNotRepeated() throws {
        let operation = try makePendingOperation(status: .awaitingSignatures)
        let statuses = StatusesCollector(following: operation, provider: provider)

        provider.listing.send([operation])
        provider.listing.send([operation])

        #expect(statuses.received == [.awaitingSignatures])
    }
}

// MARK: - Fixtures

private extension JointAccountOperationDetailsViewModelBuilderTests {
    func makePendingOperation(status: JointAccountOperationStatus) throws -> JointAccountPendingOperation {
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
            operation: JointAccountCompositionFixture.coinTransfer(status: status),
            innerCallType: .transfer(.coin(destination: Constants.recipient, value: 1_000_000_000_000_000))
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

    init(following operation: JointAccountPendingOperation, provider: any JointAccountPendingOperationsProvider) {
        subscription = JointAccountOperationDetailsViewModelBuilder()
            .contentPublisher(of: operation.operation.id, provider: provider)
            .sink { [statuses] content in
                statuses.withLock { $0.append(content.status) }
            }
    }

    var received: [JointAccountOperationDetailsViewModel.Status] {
        statuses.withLock { $0 }
    }
}

private final class PendingOperationsProviderStub: JointAccountPendingOperationsProvider {
    let listing = PassthroughSubject<[JointAccountPendingOperation], Never>()

    var pendingOperations: [JointAccountPendingOperation] { [] }

    var pendingOperationsPublisher: AnyPublisher<[JointAccountPendingOperation], Never> {
        listing.eraseToAnyPublisher()
    }

    func requestFrequentUpdates() -> AnyCancellable {
        AnyCancellable {}
    }
}
