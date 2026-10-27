//
//  SendAmountExternalUpdaterMocks.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
@testable import Tangem

// MARK: - SendAmountExternalUpdatableViewModel

final class SendAmountExternalUpdatableViewModelMock: SendAmountExternalUpdatableViewModel {
    private(set) var externalUpdateCalls: [SendAmount?] = []

    func externalUpdate(amount: SendAmount?) {
        externalUpdateCalls.append(amount)
    }
}

// MARK: - SendAmountInteractor

final class SendAmountInteractorMock: SendAmountInteractor {
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
