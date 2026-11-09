//
//  SendAmountViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import Foundation
import Testing
import TangemExpress
import TangemFoundation
@testable import Tangem

@Suite("SendAmountViewModel", .timeLimit(.minutes(1)))
struct SendAmountViewModelTests {
    @MainActor
    @Test("Fixed rate: switching only the receive token network updates the receive row icon")
    func fixedRateReceiveNetworkSwitchUpdatesIcon() async throws {
        let usdtERC20 = SendSourceTokenStub(tokenItem: Self.usdt(contractAddress: "0xdac17f958d2ee523a2206206994597c13d831ec7", blockchain: .ethereum(testnet: false)))
        let usdtTRC20 = SendSourceTokenStub(tokenItem: Self.usdt(contractAddress: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t", blockchain: .tron(testnet: false)))
        let sut = makeSUT(providerRateTypes: [.fixed])
        _ = try await sut.$providerRateTypes.first { $0.contains(.fixed) }.async()

        sut.updateDestinationToken(destinationToken: usdtERC20, amount: .loading, isApproximate: false)
        sut.updateDestinationToken(destinationToken: usdtTRC20, amount: .loading, isApproximate: false)

        guard case .selectedEditableAmount(let expanded, let compact) = sut.destinationTokenViewType else {
            Issue.record("Expected the editable receive row")
            return
        }

        let expectedIcon = TokenIconInfoBuilder().build(from: usdtTRC20.tokenItem, isCustom: false)
        #expect(expanded.tokenIconInfo == expectedIcon)
        #expect(compact.tokenIconInfo == expectedIcon)
    }

    @MainActor
    @Test("Fixed rate: an update for the same receive token does not rebuild the receive row")
    func fixedRateSameReceiveTokenDoesNotRebuildRow() async throws {
        let usdtERC20 = Self.usdt(contractAddress: "0xdac17f958d2ee523a2206206994597c13d831ec7", blockchain: .ethereum(testnet: false))
        let sut = makeSUT(providerRateTypes: [.fixed])
        _ = try await sut.$providerRateTypes.first { $0.contains(.fixed) }.async()

        var rebuildCount = 0
        let cancellable = sut.$destinationTokenViewType.dropFirst().sink { _ in rebuildCount += 1 }

        sut.updateDestinationToken(destinationToken: SendSourceTokenStub(tokenItem: usdtERC20), amount: .loading, isApproximate: false)
        sut.updateDestinationToken(destinationToken: SendSourceTokenStub(tokenItem: usdtERC20), amount: .loading, isApproximate: false)

        #expect(rebuildCount == 1)
        cancellable.cancel()
    }

    @MainActor
    @Test(
        "Losing the fixed rate after a receive amount was entered quotes the send amount instead",
        .enabled(if: FeatureProvider.isAvailable(.hideRejectedSwapProviders))
    )
    func losingFixedRateQuotesSendAmount() async throws {
        let (sut, interactor) = try await loseFixedRateAfterEnteringReceiveAmount()

        #expect(sut.activeField == .send)
        #expect(interactor.sourceAmountUpdates == [2])
    }

    @MainActor
    @Test(
        "A failed provider load after a receive amount was entered keeps the receive amount",
        .enabled(if: FeatureProvider.isAvailable(.hideRejectedSwapProviders))
    )
    func failedProviderLoadKeepsReceiveAmount() async throws {
        let (_, interactor) = try await loseFixedRateAfterEnteringReceiveAmount(then: [[]])

        #expect(interactor.sourceAmountUpdates.isEmpty)
    }

    @MainActor
    @Test(
        "Only float providers loading after a failed load quotes the send amount instead",
        .enabled(if: FeatureProvider.isAvailable(.hideRejectedSwapProviders))
    )
    func floatOnlyAfterFailedLoadQuotesSendAmount() async throws {
        let (_, interactor) = try await loseFixedRateAfterEnteringReceiveAmount(then: [[], [.float]])

        #expect(interactor.sourceAmountUpdates == [2])
    }

    @MainActor
    @Test(
        "Without the toggle, losing the fixed rate after a receive amount was entered does not quote the send amount",
        .enabled(if: !FeatureProvider.isAvailable(.hideRejectedSwapProviders))
    )
    func losingFixedRateWithoutToggleKeepsReceiveAmount() async throws {
        let (_, interactor) = try await loseFixedRateAfterEnteringReceiveAmount()

        #expect(interactor.sourceAmountUpdates.isEmpty)
    }

    @MainActor
    @Test("Losing the fixed rate after a send amount was entered does not quote again")
    func losingFixedRateKeepsSendAmountQuote() async throws {
        let rateTypes = CurrentValueSubject<Set<ExpressProviderRateType>, Never>([.fixed, .float])
        let interactor = InteractorStub()
        let sut = makeSUT(providerRateTypesPublisher: rateTypes.eraseToAnyPublisher(), interactor: interactor)
        _ = try await sut.$providerRateTypes.first { $0.contains(.fixed) }.async()

        sut.sourceAmountField.onValueChanged?(2)

        rateTypes.send([.float])
        _ = try await sut.$providerRateTypes.first { !$0.contains(.fixed) }.async()

        #expect(interactor.sourceAmountUpdates == [2])
    }
}

private extension SendAmountViewModelTests {
    static func usdt(contractAddress: String, blockchain: Blockchain) -> TokenItem {
        let token = Token(name: "Tether", symbol: "USDT", contractAddress: contractAddress, decimalCount: 6, id: "tether")
        return .token(token, .init(blockchain, derivationPath: nil))
    }

    @MainActor
    func loseFixedRateAfterEnteringReceiveAmount(
        then updates: [Set<ExpressProviderRateType>] = [[.float]]
    ) async throws -> (SendAmountViewModel, InteractorStub) {
        let rateTypes = CurrentValueSubject<Set<ExpressProviderRateType>, Never>([.fixed, .float])
        let interactor = InteractorStub()
        let sut = makeSUT(providerRateTypesPublisher: rateTypes.eraseToAnyPublisher(), interactor: interactor)
        _ = try await sut.$providerRateTypes.first { $0.contains(.fixed) }.async()

        let usdt = Self.usdt(contractAddress: "0xdac17f958d2ee523a2206206994597c13d831ec7", blockchain: .ethereum(testnet: false))
        sut.updateDestinationToken(destinationToken: SendSourceTokenStub(tokenItem: usdt), amount: .loading, isApproximate: false)
        sut.destinationAmountField?.onValueChanged?(23)
        sut.sourceAmountField.updateAmountsUI(amount: SendAmount(type: .typical(crypto: 2, fiat: 23)))

        updates.forEach(rateTypes.send)
        _ = try await sut.$providerRateTypes.first { $0 == updates.last }.async()

        return (sut, interactor)
    }

    func makeSUT(providerRateTypes: Set<ExpressProviderRateType>) -> SendAmountViewModel {
        makeSUT(providerRateTypesPublisher: .just(output: providerRateTypes), interactor: InteractorStub())
    }

    func makeSUT(
        providerRateTypesPublisher: AnyPublisher<Set<ExpressProviderRateType>, Never>,
        interactor: InteractorStub
    ) -> SendAmountViewModel {
        SendAmountViewModel(
            sourceToken: SendSourceTokenStub(),
            flowActionType: .send,
            interactor: interactor,
            analyticsLogger: AnalyticsLoggerStub(),
            shouldStartFromTokensList: false,
            providerRateTypesPublisher: providerRateTypesPublisher
        )
    }

    final class InteractorStub: SendAmountInteractor {
        private(set) var sourceAmountUpdates: [Decimal?] = []

        var isReceiveTokenSelectionAvailable: Bool { true }
        var sourceFieldInfoPublisher: AnyPublisher<SendAmountViewModel.BottomInfoTextType?, Never> { .just(output: nil) }
        var receiveFieldInfoPublisher: AnyPublisher<SendAmountViewModel.BottomInfoTextType?, Never> { .just(output: nil) }
        var isValidPublisher: AnyPublisher<Bool, Never> { .just(output: true) }
        var sourceTokenPublisher: AnyPublisher<LoadingResult<any SendSourceToken, any Error>, Never> { .empty }
        var sourceAmountPublisher: AnyPublisher<LoadingResult<SendAmount, Error>, Never> { .empty }
        var receivedTokenPublisher: AnyPublisher<LoadingResult<any SendReceiveToken, any Error>, Never> { .empty }
        var receivedTokenAmountPublisher: AnyPublisher<LoadingResult<SendAmount, Error>, Never> { .empty }
        var highPriceImpactPublisher: AnyPublisher<HighPriceImpactCalculator.Result?, Never> { .just(output: nil) }
        var isReceiveAmountApproximatePublisher: AnyPublisher<Bool, Never> { .just(output: false) }

        func update(sourceAmount: Decimal?) throws -> SendAmount? {
            sourceAmountUpdates.append(sourceAmount)
            return sourceAmount.map { SendAmount(type: .typical(crypto: $0, fiat: $0)) }
        }

        func update(sourceCryptoAmount: Decimal?) throws -> SendAmount? { nil }
        func update(sourceType: SendAmountCalculationType) throws -> SendAmount? { nil }
        func updateToMaxAmount() throws -> SendAmount { SendAmount(type: .typical(crypto: 0, fiat: 0)) }
        func update(receiveAmount: Decimal?) -> SendAmount? {
            receiveAmount.map { SendAmount(type: .typical(crypto: $0, fiat: $0)) }
        }

        func update(receiveType: SendAmountCalculationType) {}
        func validateExternalSourceAmount(_ amount: SendAmount?) {}
        func userDidRequestClearReceiveToken() {}
    }

    struct AnalyticsLoggerStub: SendAmountAnalyticsLogger {
        func logTapMaxAmount() {}
        func logTapConvertToAnotherToken() {}
        func logAmountStepOpened() {}
        func logAmountStepReopened() {}
    }
}
