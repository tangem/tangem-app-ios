//
//  SwapTrustlineRestrictionTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemLocalization
import Testing
@testable import BlockchainSdk
@testable import Tangem

@Suite("Swap destination trustline restriction")
struct SwapTrustlineRestrictionTests {
    private let stellar: Blockchain = .stellar(curve: .ed25519, testnet: false)

    @Test("A destination with an unfulfilled trustline reports the trustline receiving restriction")
    func missingTrustlineReportsReceivingRestriction() async throws {
        let walletModel = WalletModelTestsMock(fiatBalance: 0, priceChange24h: nil)
        walletModel.assetRequirementsManagerMock = AssetRequirementsManagerStub(
            condition: .requiresTrustline(
                blockchain: stellar,
                trustlineReserve: Amount(with: stellar, value: 0.5),
                isProcessing: false
            )
        )

        let provider = WalletModelReceivingRestrictionsProvider(
            userWalletInfo: SendSourceTokenStub().userWalletInfo,
            walletModel: walletModel
        )

        let restriction = try await provider.restriction(expectAmount: .zero)

        guard case .requiresTrustline = restriction else {
            Issue.record("Expected .requiresTrustline, got \(String(describing: restriction))")
            return
        }
    }

    @Test("A trustline operation pending on the network still reports the restriction")
    func pendingTrustlineStillReportsRestriction() async throws {
        let walletModel = WalletModelTestsMock(fiatBalance: 0, priceChange24h: nil)
        walletModel.assetRequirementsManagerMock = AssetRequirementsManagerStub(
            condition: .requiresTrustline(
                blockchain: stellar,
                trustlineReserve: Amount(with: stellar, value: 0.5),
                isProcessing: true
            )
        )

        let provider = WalletModelReceivingRestrictionsProvider(
            userWalletInfo: SendSourceTokenStub().userWalletInfo,
            walletModel: walletModel
        )

        let restriction = try await provider.restriction(expectAmount: .zero)

        guard case .requiresTrustline = restriction else {
            Issue.record("Expected .requiresTrustline, got \(String(describing: restriction))")
            return
        }
    }

    @Test("An unfunded account with no trustlines still reports the restriction", arguments: [
        WalletModelState.noAccount(message: "", amountToCreate: 1),
        WalletModelState.loaded(0),
    ])
    func unfundedAccountReportsRestriction(state: WalletModelState) async throws {
        let walletModel = WalletModelTestsMock(fiatBalance: 0, priceChange24h: nil)
        walletModel.stateMock = state
        walletModel.assetRequirementsManagerMock = AssetRequirementsManagerStub(
            condition: .requiresTrustline(
                blockchain: stellar,
                trustlineReserve: Amount(with: stellar, value: 0.5),
                isProcessing: false
            )
        )

        let provider = WalletModelReceivingRestrictionsProvider(
            userWalletInfo: SendSourceTokenStub().userWalletInfo,
            walletModel: walletModel
        )

        let restriction = try await provider.restriction(expectAmount: .zero)

        guard case .requiresTrustline = restriction else {
            Issue.record("Expected .requiresTrustline for \(state), got \(String(describing: restriction))")
            return
        }
    }

    @Test("A wallet with settled data is answered without another update", arguments: [
        WalletModelState.loaded(0),
        WalletModelState.noAccount(message: "", amountToCreate: 1),
    ])
    func settledWalletIsNotReloaded(state: WalletModelState) async throws {
        let walletModel = WalletModelTestsMock(fiatBalance: 0, priceChange24h: nil)
        walletModel.stateMock = state
        walletModel.assetRequirementsManagerMock = AssetRequirementsManagerStub(condition: nil)

        let provider = WalletModelReceivingRestrictionsProvider(
            userWalletInfo: SendSourceTokenStub().userWalletInfo,
            walletModel: walletModel
        )

        #expect(provider.isRestrictionKnown)

        _ = try await provider.restriction(expectAmount: .zero)

        #expect(walletModel.updateCallCount == 0)
    }

    @Test("A wallet nobody loads is updated once and awaited until it settles", .timeLimit(.minutes(1)))
    func createdWalletIsUpdatedAndAwaited() async throws {
        let walletModel = WalletModelTestsMock(fiatBalance: 0, priceChange24h: nil)
        walletModel.stateMock = .created
        walletModel.assetRequirementsManagerMock = AssetRequirementsManagerStub(condition: nil)

        let provider = WalletModelReceivingRestrictionsProvider(
            userWalletInfo: SendSourceTokenStub().userWalletInfo,
            walletModel: walletModel
        )

        #expect(provider.isRestrictionKnown == false)

        let hasReturned = OSAllocatedUnfairLock(initialState: false)
        let wait = Task {
            _ = try await provider.restriction(expectAmount: .zero)
            hasReturned.withLock { $0 = true }
        }

        try await waitUntil { walletModel.updateCallCount == 1 }
        #expect(hasReturned.withLock { $0 } == false)

        walletModel.stateMock = .loaded(0)
        try await wait.value

        #expect(hasReturned.withLock { $0 })
        #expect(walletModel.updateCallCount == 1)
    }

    @Test("A wallet that is already loading is only awaited", .timeLimit(.minutes(1)))
    func loadingWalletIsOnlyAwaited() async throws {
        let walletModel = WalletModelTestsMock(fiatBalance: 0, priceChange24h: nil)
        walletModel.stateMock = .loading
        walletModel.assetRequirementsManagerMock = AssetRequirementsManagerStub(condition: nil)

        let provider = WalletModelReceivingRestrictionsProvider(
            userWalletInfo: SendSourceTokenStub().userWalletInfo,
            walletModel: walletModel
        )

        #expect(provider.isRestrictionKnown == false)

        let hasReturned = OSAllocatedUnfairLock(initialState: false)
        let wait = Task {
            _ = try await provider.restriction(expectAmount: .zero)
            hasReturned.withLock { $0 = true }
        }

        try await waitUntil { walletModel.stateSubscriptionCount == 1 }
        #expect(hasReturned.withLock { $0 } == false)

        walletModel.stateMock = .loaded(0)
        try await wait.value

        #expect(walletModel.updateCallCount == 0)
    }

    @Test("An unreachable wallet is retried and then reported as unavailable data")
    func unreachableWalletFailsAfterRetry() async throws {
        let walletModel = WalletModelTestsMock(fiatBalance: 0, priceChange24h: nil)
        walletModel.stateMock = .failed(error: "")
        walletModel.assetRequirementsManagerMock = AssetRequirementsManagerStub(condition: nil)

        let provider = WalletModelReceivingRestrictionsProvider(
            userWalletInfo: SendSourceTokenStub().userWalletInfo,
            walletModel: walletModel
        )

        await #expect(throws: ReceivingRestrictionsError.restrictionsDataUnavailable) {
            _ = try await provider.restriction(expectAmount: .zero)
        }

        #expect(walletModel.updateCallCount == 1)
    }

    @Test("A fulfilled trustline keeps the destination unrestricted")
    func fulfilledTrustlineReportsNoRestriction() async throws {
        let walletModel = WalletModelTestsMock(fiatBalance: 0, priceChange24h: nil)
        walletModel.assetRequirementsManagerMock = AssetRequirementsManagerStub(condition: nil)

        let provider = WalletModelReceivingRestrictionsProvider(
            userWalletInfo: SendSourceTokenStub().userWalletInfo,
            walletModel: walletModel
        )

        #expect(try await provider.restriction(expectAmount: .zero) == nil)
    }

    @Test("A destination that cannot require a trustline is answered without loading it")
    func destinationWithoutAssetRequirementsIsNotLoaded() async throws {
        let walletModel = WalletModelTestsMock(fiatBalance: 0, priceChange24h: nil)
        walletModel.stateMock = .created

        let provider = WalletModelReceivingRestrictionsProvider(
            userWalletInfo: SendSourceTokenStub().userWalletInfo,
            walletModel: walletModel
        )

        #expect(provider.isRestrictionKnown)
        #expect(try await provider.restriction(expectAmount: .zero) == nil)
        #expect(walletModel.updateCallCount == 0)
    }

    @Test("A missing trustline is reported ahead of an incomplete backup")
    func trustlineOutranksIncompleteBackup() async throws {
        let walletModel = WalletModelTestsMock(fiatBalance: 0, priceChange24h: nil)
        walletModel.assetRequirementsManagerMock = AssetRequirementsManagerStub(
            condition: .requiresTrustline(
                blockchain: stellar,
                trustlineReserve: Amount(with: stellar, value: 0.5),
                isProcessing: false
            )
        )

        let provider = WalletModelReceivingRestrictionsProvider(
            userWalletInfo: userWalletInfo(backupState: .incompleteBackup),
            walletModel: walletModel
        )

        let restriction = try await provider.restriction(expectAmount: .zero)

        guard case .requiresTrustline = restriction else {
            Issue.record("Expected .requiresTrustline, got \(String(describing: restriction))")
            return
        }
    }

    @Test("An incomplete backup is reported when the destination needs no trustline")
    func incompleteBackupIsReportedWithoutTrustline() async throws {
        let walletModel = WalletModelTestsMock(fiatBalance: 0, priceChange24h: nil)
        walletModel.assetRequirementsManagerMock = AssetRequirementsManagerStub(condition: nil)

        let provider = WalletModelReceivingRestrictionsProvider(
            userWalletInfo: userWalletInfo(backupState: .incompleteBackup),
            walletModel: walletModel
        )

        let restriction = try await provider.restriction(expectAmount: .zero)

        guard case .incompleteBackup = restriction else {
            Issue.record("Expected .incompleteBackup, got \(String(describing: restriction))")
            return
        }
    }

    private func userWalletInfo(backupState: UserWalletBackupState) -> UserWalletInfo {
        UserWalletInfo(
            name: "Test",
            id: UserWalletId(value: Data([0x01])),
            config: UserWalletConfigStub(),
            backupState: backupState,
            refcode: nil,
            signerFactory: TangemSignerFactory(),
            emailDataProvider: EmailDataProviderStub()
        )
    }

    private func waitUntil(_ condition: @escaping () -> Bool) async throws {
        for _ in 0 ..< 500 {
            if condition() {
                return
            }

            try await Task.sleep(for: .milliseconds(10))
        }

        throw TimeoutError()
    }

    private struct TimeoutError: Error {}
}

// MARK: - Notification manager mapping

@Suite("CommonSwapNotificationManager — trustline banner mapping")
struct SwapNotificationManagerTrustlineMappingTests {
    private let stellar: Blockchain = .stellar(curve: .ed25519, testnet: false)

    @Test("The trustline restriction produces the banner")
    func trustlineRestrictionProducesBanner() {
        let destination = SwapableTokenStub(blockchain: stellar)
        #expect(mapToEvents(state: .restriction(.trustlineRequired(destination: destination), quote: .none)) == [.trustlineRequired])
    }

    @Test("Another restriction does not produce the trustline banner")
    func otherRestrictionProducesNoTrustlineBanner() {
        let events = mapToEvents(state: .restriction(.regionRestricted, quote: .none))

        #expect(events.count == 1)

        guard case .regionRestricted = events.first else {
            Issue.record("Expected .regionRestricted, got \(String(describing: events.first))")
            return
        }
    }

    @Test("An unreachable destination reports the generic error instead of claiming a missing trustline")
    func unreachableDestinationProducesGenericError() {
        let sut = CommonSwapNotificationManager()
        let events = sut.mapToEvents(
            source: .success(SwapableTokenStub(blockchain: .ethereum(testnet: false))),
            receive: .success(SwapableTokenStub(blockchain: stellar)),
            state: .failure(ReceivingRestrictionsError.restrictionsDataUnavailable),
            selectedFee: nil,
            slippage: .auto
        )

        #expect(events.count == 1)

        guard case .refreshRequired(let title, let message, nil, nil) = events.first else {
            Issue.record("Expected .refreshRequired, got \(String(describing: events.first))")
            return
        }

        #expect(title == Localization.commonError)
        #expect(message == Localization.commonUnknownError)
    }

    private func mapToEvents(state: SwapModel.LoadedState) -> [SwapNotificationEvent] {
        CommonSwapNotificationManager().mapToEvents(
            source: .success(SwapableTokenStub(blockchain: .ethereum(testnet: false))),
            receive: .success(SwapableTokenStub(blockchain: stellar)),
            state: .loaded(.swap(selected: .none, providers: .empty), state: state),
            selectedFee: nil,
            slippage: .auto
        )
    }
}

// MARK: - Stubs

final class AssetRequirementsManagerStub: AssetRequirementsManager {
    var condition: AssetRequirementsCondition?

    init(condition: AssetRequirementsCondition?) {
        self.condition = condition
    }

    func requirementsCondition(for asset: Asset) -> AssetRequirementsCondition? {
        condition
    }

    func fulfillRequirements(for asset: Asset, signer: any TransactionSigner) -> AnyPublisher<Void, Error> {
        Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func feeStatusForRequirement(asset: Asset) -> AnyPublisher<AssetRequirementFeeStatus, Never> {
        Just(.sufficient).eraseToAnyPublisher()
    }
}
