//
//  SendSummaryInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemLocalization

protocol SendSummaryInteractor: AnyObject {
    var isUpdatingPublisher: AnyPublisher<Bool, Never> { get }
    var isReadyToSendPublisher: AnyPublisher<Bool, Never> { get }
    var transactionDescription: AnyPublisher<AttributedString?, Never> { get }
    var isNotificationButtonIsLoading: AnyPublisher<Bool, Never> { get }
}

class CommonSendSummaryInteractor {
    private weak var input: SendSummaryInput?
    private weak var output: SendSummaryOutput?
    private weak var swapModelStateProvider: SwapModelStateProvider?

    private let sendDescriptionBuilder: SendTransactionSummaryDescriptionBuilder
    private let sendWithSwapDescriptionBuilder: SendWithSwapTransactionSummaryDescriptionBuilder
    private let stakingDescriptionBuilder: StakingTransactionSummaryDescriptionBuilder

    init(
        input: SendSummaryInput,
        output: SendSummaryOutput,
        swapModelStateProvider: SwapModelStateProvider?,
        sendDescriptionBuilder: SendTransactionSummaryDescriptionBuilder,
        sendWithSwapDescriptionBuilder: SendWithSwapTransactionSummaryDescriptionBuilder,
        stakingDescriptionBuilder: StakingTransactionSummaryDescriptionBuilder
    ) {
        self.input = input
        self.output = output
        self.swapModelStateProvider = swapModelStateProvider
        self.sendDescriptionBuilder = sendDescriptionBuilder
        self.sendWithSwapDescriptionBuilder = sendWithSwapDescriptionBuilder
        self.stakingDescriptionBuilder = stakingDescriptionBuilder
    }
}

extension CommonSendSummaryInteractor: SendSummaryInteractor {
    var transactionDescription: AnyPublisher<AttributedString?, Never> {
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

    var isUpdatingPublisher: AnyPublisher<Bool, Never> {
        guard let swapModelStateProvider else {
            return Empty().eraseToAnyPublisher()
        }

        return swapModelStateProvider
            .statePublisher
            .filter { $0.filter(loading: [.autoupdate]) }
            .map { $0.isLoading }
            .eraseToAnyPublisher()
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

private extension CommonSendSummaryInteractor {
    private func summaryDescription(data: SendSummaryTransactionData?) -> AttributedString? {
        switch data {
        case .none, .swap:
            return nil
        case .staking(let amount, let schedule):
            let description = stakingDescriptionBuilder.makeDescription(amount: amount, schedule: schedule)
            return description
        case .send(let amount, let fee):
            let description = sendDescriptionBuilder.makeDescription(amount: amount, fee: fee)
            return description
        case .sendWithSwap(let amount, let fee, let provider):
            let description = sendWithSwapDescriptionBuilder.makeDescription(amount: amount, fee: fee, provider: provider)
            return description
        }
    }
}
