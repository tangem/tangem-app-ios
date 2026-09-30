//
//  SendAmountInteractorSaverTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import Testing
@testable import Tangem

@Suite("CommonSendAmountInteractorSaver")
struct SendAmountInteractorSaverTests {
    @Test("cancelChanges restores the captured amount through the unit-safe crypto path")
    func cancelRestoresCryptoAmount() {
        let input = SourceTokenAmountInputMock()
        let output = SourceTokenAmountOutputMock()
        let viewModel = ExternalUpdatableViewModelMock()
        let interactor = InteractorMock()

        let saver = CommonSendAmountInteractorSaver(
            sourceTokenAmountInput: input,
            sourceTokenAmountOutput: output,
            receiveTokenInput: nil,
            receiveTokenOutput: nil
        )
        saver.updater = SendAmountExternalUpdater(viewModel: viewModel, interactor: interactor)

        // Captured while the field was in fiat mode: 1 ETH shown as 3000 $.
        let captured = SendAmount(type: .alternative(fiat: 3000, crypto: 1))
        input.sourceAmount = .success(captured)
        saver.captureValue()

        // The user switches the field back to crypto and cancels.
        saver.cancelChanges()

        // The restored value must be the crypto amount regardless of the calculation type at capture time;
        // going through `update(sourceAmount:)` would have re-read `main` (3000, the fiat value) as 3000 ETH.
        #expect(interactor.updateSourceCryptoAmountCalls == [1])
        #expect(interactor.updateSourceAmountCalls.isEmpty)
        #expect(output.receivedAmounts == [captured])
    }

    @Test("cancelChanges with nothing captured resets the amount")
    func cancelWithoutCaptureClearsAmount() {
        let input = SourceTokenAmountInputMock()
        let output = SourceTokenAmountOutputMock()
        let interactor = InteractorMock()

        let saver = CommonSendAmountInteractorSaver(
            sourceTokenAmountInput: input,
            sourceTokenAmountOutput: output,
            receiveTokenInput: nil,
            receiveTokenOutput: nil
        )
        saver.updater = SendAmountExternalUpdater(viewModel: ExternalUpdatableViewModelMock(), interactor: interactor)

        saver.cancelChanges()

        #expect(interactor.updateSourceCryptoAmountCalls == [nil])
        #expect(output.receivedAmounts == [nil])
    }
}

// MARK: - Test doubles

private final class SourceTokenAmountInputMock: SendSourceTokenAmountInput {
    var sourceAmount: LoadingResult<SendAmount, any Error> = .loading
    var sourceAmountPublisher: AnyPublisher<LoadingResult<SendAmount, Error>, Never> { .just(output: sourceAmount) }
}

private final class SourceTokenAmountOutputMock: SendSourceTokenAmountOutput {
    private(set) var receivedAmounts: [SendAmount?] = []

    func sourceAmountDidChanged(amount: SendAmount?) {
        receivedAmounts.append(amount)
    }
}

private final class ExternalUpdatableViewModelMock: SendAmountExternalUpdatableViewModel {
    func externalUpdate(amount: SendAmount?) {}
}

private final class InteractorMock: SendAmountInteractor {
    private(set) var updateSourceAmountCalls: [Decimal?] = []
    private(set) var updateSourceCryptoAmountCalls: [Decimal?] = []

    var isReceiveTokenSelectionAvailable: Bool { false }
    var sourceFieldInfoPublisher: AnyPublisher<SendAmountViewModel.BottomInfoTextType?, Never> { .just(output: nil) }
    var receiveFieldInfoPublisher: AnyPublisher<SendAmountViewModel.BottomInfoTextType?, Never> { .just(output: nil) }
    var isValidPublisher: AnyPublisher<Bool, Never> { .just(output: true) }
    var sourceTokenPublisher: AnyPublisher<LoadingResult<any SendSourceToken, any Error>, Never> { .empty }
    var sourceAmountPublisher: AnyPublisher<LoadingResult<SendAmount, Error>, Never> { .empty }
    var receivedTokenPublisher: AnyPublisher<LoadingResult<any SendReceiveToken, any Error>, Never> { .empty }
    var receivedTokenAmountPublisher: AnyPublisher<LoadingResult<SendAmount, Error>, Never> { .empty }
    var highPriceImpactPublisher: AnyPublisher<HighPriceImpactCalculator.Result?, Never> { .just(output: nil) }
    var isReceiveAmountApproximatePublisher: AnyPublisher<Bool, Never> { .just(output: false) }

    func update(sourceType: SendAmountCalculationType) throws -> SendAmount? { nil }
    func updateToMaxAmount() throws -> SendAmount { SendAmount(type: .typical(crypto: 0, fiat: 0)) }
    func update(receiveAmount: Decimal?) -> SendAmount? { nil }
    func update(receiveType: SendAmountCalculationType) {}
    func validateExternalSourceAmount(_ amount: SendAmount?) {}
    func userDidRequestClearReceiveToken() {}

    func update(sourceAmount: Decimal?) throws -> SendAmount? {
        updateSourceAmountCalls.append(sourceAmount)
        return nil
    }

    func update(sourceCryptoAmount: Decimal?) throws -> SendAmount? {
        updateSourceCryptoAmountCalls.append(sourceCryptoAmount)
        return nil
    }
}
