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
    private weak var input: SendFeeInput?
    private weak var output: SendFeeOutput?
    private let provider: SendFeeProvider

    private var lastUpdateStartTime = Date()
    private let informationValidityInterval: TimeInterval = 60
    private var bag: Set<AnyCancellable> = []

    init(input: SendFeeInput, output: SendFeeOutput, provider: SendFeeProvider) {
        self.input = input
        self.output = output
        self.provider = provider

        bind()
    }

    private func bind() {
        input?
            .selectedFeePublisher
            .withWeakCaptureOf(self)
            .sink { service, _ in
                service.informationDidUpdated()
            }
            .store(in: &bag)
    }

    private func compare(selected: TokenFee?, fees: [TokenFee]) -> InformationRelevanceServiceUpdateResult {
        let oldFeeValue = selected?.value.value?.amount.value
        let newFee = fees.first(where: { $0.option == selected?.option })

        guard let oldFeeValue,
              let newFee,
              let newFeeValue = newFee.value.value?.amount.value,
              newFeeValue > oldFeeValue else {
            return .ok
        }

        output?.userDidSelect(selectedFee: newFee)
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
        defer {
            provider.updateFees()
        }

        let oldFee = input?.selectedFee

        // Catch the subscriptions
        return provider
            .feesPublisher
            // Skip the old values
            .dropFirst()
            .withWeakCaptureOf(self)
            .tryMap { service, fees in
                if let error = fees.eraseToLoadingResult().error {
                    throw error
                }

                service.informationDidUpdated()
                return service.compare(selected: oldFee, fees: fees)
            }
            .eraseToAnyPublisher()
    }
}

enum InformationRelevanceServiceUpdateResult {
    case ok
    case feeWasIncreased
}
