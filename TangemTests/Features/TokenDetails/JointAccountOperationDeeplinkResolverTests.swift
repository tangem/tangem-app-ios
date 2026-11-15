//
//  JointAccountOperationDeeplinkResolverTests.swift
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

@Suite("Joint operation deeplink resolver", .timeLimit(.minutes(1)))
struct JointAccountOperationDeeplinkResolverTests {
    private let delegate = JointAccountModelDelegateMock()

    @Test("An unfinished operation the provider lists is opened without reading it from the endpoint", arguments: [
        JointAccountOperationStatus.awaitingSignatures,
        .pending,
    ])
    func listedOperationIsOpenedWithoutTheEndpoint(status: JointAccountOperationStatus) async throws {
        let provider = PendingOperationsProviderSpy()
        let listed = try makePendingOperation(id: Constants.operationId, status: status, provider: provider)
        provider.listedOperations = [listed]
        let sut = makeSUT(provider: provider)

        let resolved = try await sut.resolve(operationId: Constants.operationId)

        #expect(resolved == listed)
        #expect(provider.loadedIds.isEmpty)
    }

    @Test("An operation the provider does not list is read from the endpoint by its id")
    func unlistedOperationIsReadFromTheEndpoint() async throws {
        let provider = PendingOperationsProviderSpy()
        provider.listedOperations = [try makePendingOperation(id: "another", status: .awaitingSignatures, provider: provider)]
        let loaded = try makePendingOperation(id: Constants.operationId, status: .executed, provider: provider)
        provider.loadedAnswer = .success(loaded)
        let sut = makeSUT(provider: provider)

        let resolved = try await sut.resolve(operationId: Constants.operationId)

        #expect(resolved == loaded)
        #expect(provider.loadedIds == [Constants.operationId])
    }

    @Test("An operation the endpoint does not know, does not show this wallet, or will not read while the feature is off is reported as unavailable", arguments: [
        JointOperationError.operationNotFound as any Error,
        JointOperationError.notAMember,
        CommonJointAccountPendingOperationsRepository.InternalError.featureUnavailable,
    ])
    func unavailableOperationIsNotOpened(error: any Error) async throws {
        let provider = PendingOperationsProviderSpy()
        provider.loadedAnswer = .failure(error)
        let sut = makeSUT(provider: provider)

        await #expect(throws: JointAccountOperationDeeplinkResolver.Error.operationIsUnavailable) {
            try await sut.resolve(operationId: Constants.operationId)
        }
    }

    @Test("An operation in a token this wallet has not added is reported as unavailable")
    func operationWithoutItsWalletIsUnavailable() async throws {
        let provider = PendingOperationsProviderSpy()
        provider.loadedAnswer = .failure(JointAccountPendingOperationsProviderError.walletNotFound)
        let sut = makeSUT(provider: provider)

        await #expect(throws: JointAccountOperationDeeplinkResolver.Error.operationIsUnavailable) {
            try await sut.resolve(operationId: Constants.operationId)
        }
    }

    @Test("An endpoint that does not answer in time ends the wait with its own error")
    func slowEndpointTimesOut() async throws {
        let gate = TestGate()
        let provider = PendingOperationsProviderSpy()
        provider.loadGate = gate
        let sut = makeSUT(provider: provider, timeout: .zero)

        await #expect(throws: JointAccountOperationDeeplinkResolver.Error.timedOut) {
            try await sut.resolve(operationId: Constants.operationId)
        }

        gate.open()
    }

    @Test("Any other failure is passed on to be logged")
    func otherFailureIsPassedOn() async throws {
        let provider = PendingOperationsProviderSpy()
        provider.loadedAnswer = .failure("The endpoint is down")
        let sut = makeSUT(provider: provider)

        await #expect(throws: String.self) {
            try await sut.resolve(operationId: Constants.operationId)
        }
    }
}

// MARK: - Helpers

private extension JointAccountOperationDeeplinkResolverTests {
    func makeSUT(provider: PendingOperationsProviderSpy, timeout: Duration = .seconds(30)) -> JointAccountOperationDeeplinkResolver {
        JointAccountOperationDeeplinkResolver(jointAccount: makeJointAccount(provider: provider), timeout: timeout)
    }

    func makeJointAccount(provider: any JointAccountPendingOperationsProvider) -> any JointAccountModel {
        CommonJointAccountModel(
            cryptoAccount: CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in }),
            derivationIdentity: JointAccountCompositionFixture.derivationIdentity,
            accountPolicy: JointAccountPolicy(membersCount: 2, signersCount: 2),
            statusProvider: JointAccountStatusProviderStub(status: .active(safeAddress: Constants.safeAddress)),
            operationsService: JointAccountOperationsServiceMock(),
            pendingOperationsProvider: provider,
            membersService: JointAccountMembersServiceMock(slots: []),
            finishedOperationsWalletUpdater: JointAccountFinishedOperationsWalletUpdater(
                pendingOperationsProvider: JointAccountPendingOperationsProviderMock(),
                walletModelsManager: WalletModelsManagerMock(),
                historyDeltaSyncing: JointOperationsHistoryDeltaSyncingStub()
            ),
            userRoleService: JointAccountUserRoleServiceMock(),
            delegate: delegate
        )
    }

    func makePendingOperation(
        id: String,
        status: JointAccountOperationStatus,
        provider: any JointAccountPendingOperationsProvider
    ) throws -> JointAccountPendingOperation {
        let operation = JointAccountCompositionFixture.coinTransfer(id: id, status: status)
        let wallet = try JointAccountWalletBuilder().build(
            walletModel: WalletModelTestsMock(
                tokenItem: Constants.coin,
                isEmpty: false,
                account: makeJointAccount(provider: provider),
                safeWalletManagerOperationsService: SafeWalletManagerOperationsServiceTestsMock()
            )
        )

        return JointAccountPendingOperation(
            wallet: wallet,
            initiator: .unlisted(address: operation.initiator),
            operation: operation,
            operationPublisher: Just(operation).eraseToAnyPublisher(),
            innerCallType: .transfer(.coin(destination: Constants.recipient, value: 1_000_000_000_000_000)),
            feeTokenItem: Constants.coin
        )
    }
}

private extension JointAccountOperationDeeplinkResolverTests {
    enum Constants {
        static let operationId = "deeplinked"
        static let safeAddress = "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"
        static let recipient = "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c"
        static let coin: TokenItem = .blockchain(BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil))
    }
}

// MARK: - Stubs

private final class PendingOperationsProviderSpy: JointAccountPendingOperationsProvider {
    var listedOperations: [JointAccountPendingOperation] = []
    var loadedAnswer: Result<JointAccountPendingOperation, Error> = .failure("The test handed no answer for the endpoint to read the operation with")
    var loadGate: TestGate?

    private let calls = OSAllocatedUnfairLock(initialState: Calls())

    var loadedIds: [String] {
        calls.withLock(\.loadedIds)
    }

    func hasPendingOperations(chainId: Int) -> Bool {
        false
    }

    var pendingOperationsPublisher: AnyPublisher<[JointAccountPendingOperation], Never> {
        Just(listedOperations).eraseToAnyPublisher()
    }

    func requestFrequentUpdates(operationId: String) -> AnyCancellable? {
        nil
    }

    func loadOperation(id: String) async throws -> JointAccountPendingOperation {
        calls.withLock { $0.loadedIds.append(id) }
        await loadGate?.wait()

        return try loadedAnswer.get()
    }
}

private extension PendingOperationsProviderSpy {
    struct Calls {
        var loadedIds: [String] = []
    }
}
