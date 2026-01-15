//
//  InformationRelevanceService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol InformationRelevanceService {
    var isActual: Bool { get }

    func informationDidUpdated()
    func updateInformation() -> AnyPublisher<InformationRelevanceServiceUpdateResult, Error>
}

class CommonInformationRelevanceService {
    private weak var input: SendSummaryFeeInput?
    private weak var output: SendFeeOutput?
    private let provider: SendFeeUpdater

    private var lastUpdateStartTime = Date()
    private let informationValidityInterval: TimeInterval = 60
    private var bag: Set<AnyCancellable> = []

    init(input: SendSummaryFeeInput, output: SendFeeOutput, provider: SendFeeUpdater) {
        self.input = input
        self.output = output
        self.provider = provider

        bind(input: input)
    }

    private func bind(input: SendSummaryFeeInput) {
        input
            .summaryFeePublisher
            .withWeakCaptureOf(self)
            .sink { service, _ in
                service.informationDidUpdated()
            }
            .store(in: &bag)
    }

    private func compare(oldFee: LoadableTokenFee, newFee: LoadableTokenFee) -> InformationRelevanceServiceUpdateResult {
        let oldFeeValue = oldFee.value.value?.amount.value
        let newFeeValue = newFee.value.value?.amount.value

        guard let oldFeeValue, let newFeeValue, newFeeValue > oldFeeValue else {
            return .ok
        }

        output?.feeDidChanged(fee: newFee)
        return .feeWasIncreased
    }
}

// MARK: - InformationRelevanceService

extension CommonInformationRelevanceService: InformationRelevanceService {
    var isActual: Bool {
        Date().timeIntervalSince(lastUpdateStartTime) < informationValidityInterval
    }

    func informationDidUpdated() {
        lastUpdateStartTime = Date()
    }

    func updateInformation() -> AnyPublisher<InformationRelevanceServiceUpdateResult, any Error> {
        guard let input else {
            return Empty().eraseToAnyPublisher()
        }

        defer { provider.updateFees() }

        // Catch the subscriptions
        return input
            .summaryFeePublisher
            .pairwise()
            .withWeakCaptureOf(self)
            .tryMap { service, fees in
                let (oldFee, newFee) = fees

                if let error = newFee.value.error {
                    throw error
                }

                service.informationDidUpdated()
                return service.compare(oldFee: oldFee, newFee: newFee)
            }
            .eraseToAnyPublisher()
    }
}

enum InformationRelevanceServiceUpdateResult {
    case ok
    case feeWasIncreased
}
