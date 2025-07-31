//
//  SendNewSummaryInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemLocalization

protocol SendNewSummaryInteractor: AnyObject {
    var title: String? { get }

    var isReadyToSendPublisher: AnyPublisher<Bool, Never> { get }
    var transactionDescription: AnyPublisher<SummaryDescriptionType?, Never> { get }
    var isNotificationButtonIsLoading: AnyPublisher<Bool, Never> { get }
}

enum SummaryDescriptionType {
    case string(String)
    case attributed(AttributedString)
}

class CommonSendNewSummaryInteractor {
    private weak var input: SendSummaryInput?
    private weak var output: SendSummaryOutput?
    private weak var receiveTokenInput: SendReceiveTokenInput?

    private let sendDescriptionBuilder: SendTransactionSummaryDescriptionBuilder
    private let swapDescriptionBuilder: SwapTransactionSummaryDescriptionBuilder

    init(
        input: SendSummaryInput,
        output: SendSummaryOutput,
        receiveTokenInput: SendReceiveTokenInput,
        sendDescriptionBuilder: SendTransactionSummaryDescriptionBuilder,
        swapDescriptionBuilder: SwapTransactionSummaryDescriptionBuilder
    ) {
        self.input = input
        self.output = output
        self.receiveTokenInput = receiveTokenInput
        self.sendDescriptionBuilder = sendDescriptionBuilder
        self.swapDescriptionBuilder = swapDescriptionBuilder
    }
}

extension CommonSendNewSummaryInteractor: SendNewSummaryInteractor {
    var title: String? {
        switch receiveTokenInput?.receiveToken {
        case .same(let sendSourceToken):
            return Localization.commonSend
        case .swap(let sendReceiveToken):
            return Localization.sendWithSwapTitle
        case .none:
            return nil
        }
    }

    var transactionDescription: AnyPublisher<SummaryDescriptionType?, Never> {
        guard let input else {
            assertionFailure("SendSummaryInput is not found")
            return Empty().eraseToAnyPublisher()
        }

        return input
            .summaryTransactionDataPublisher
            .withWeakCaptureOf(self)
            .map { $0.summaryDescription(data: $1) }
            .eraseToAnyPublisher()
    }

    var isNotificationButtonIsLoading: AnyPublisher<Bool, Never> {
        guard let input else {
            assertionFailure("SendSummaryInput is not found")
            return Empty().eraseToAnyPublisher()
        }

        return input.isNotificationButtonIsLoading
    }

    var isReadyToSendPublisher: AnyPublisher<Bool, Never> {
        guard let input else {
            assertionFailure("SendSummaryInput is not found")
            return Empty().eraseToAnyPublisher()
        }

        return input.isReadyToSendPublisher
    }
}

// MARK: - Private

private extension CommonSendNewSummaryInteractor {
    private func summaryDescription(data: SendSummaryTransactionData?) -> SummaryDescriptionType? {
        switch data {
        case .none, .staking:
            return nil
        case .send(let amount, let fee):
            let description = sendDescriptionBuilder.makeDescription(amount: amount, fee: fee)
            return description.map { .string($0) }
        case .swap(let provider):
            let description = swapDescriptionBuilder.makeDescription(provider: provider)
            return description.map { .attributed($0) }
        }
    }
}
