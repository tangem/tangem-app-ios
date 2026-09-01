//
//  InformationRelevanceService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

protocol InformationRelevanceService {
    var isActual: Bool { get }

    func informationDidUpdated()
    func updateInformation() -> AnyPublisher<InformationRelevanceServiceUpdateResult, Error>
}

class CommonInformationRelevanceService {
    private weak var input: SendFeeInput?
    private weak var provider: SendFeeUpdater?

    private var lastUpdateStartTime = Date()
    private let informationValidityInterval: TimeInterval = 60
    private var bag: Set<AnyCancellable> = []

    init(input: SendFeeInput, provider: SendFeeUpdater) {
        self.input = input
        self.provider = provider

        bind(input: input)
    }

    private func bind(input: SendFeeInput) {
        input
            .selectedFeePublisher
            .withWeakCaptureOf(self)
            .sink { service, _ in
                service.informationDidUpdated()
            }
            .store(in: &bag)
    }

    private func compare(oldFee: TokenFee, newFee: TokenFee) -> InformationRelevanceServiceUpdateResult {
        let oldFeeValue = oldFee.value.value?.amount.value
        let newFeeValue = newFee.value.value?.amount.value

        guard let oldFeeValue, let newFeeValue, newFeeValue > oldFeeValue else {
            return .ok
        }

        return .feeWasIncreased
    }
}

// MARK: - InformationRelevanceService

extension CommonInformationRelevanceService: InformationRelevanceService {
    var isActual: Bool {
        let currentDate = Date()
        guard currentDate.timeIntervalSince(lastUpdateStartTime) < informationValidityInterval else {
            return false
        }

        // move it in more appropriate place with general gasless refactoring
        guard let parameters = input?.selectedFee?.value.value?.parameters as? TronGaslessFeeParameters else {
            return true
        }

        return parameters.expiresAt > currentDate.addingTimeInterval(TronGaslessFeeParameters.expirationBuffer)
            && input?.isSelectedFeeActual == true
    }

    func informationDidUpdated() {
        lastUpdateStartTime = Date()
    }

    func updateInformation() -> AnyPublisher<InformationRelevanceServiceUpdateResult, any Error> {
        guard let input, let oldFee = input.selectedFee else {
            return .empty
        }

        return input
            .selectedFeePublisher
            .dropFirst()
            .withWeakCaptureOf(self)
            .tryCompactMap { service, newFee in
                if let error = newFee.value.error {
                    throw error
                }

                guard input.isSelectedFeeActual else {
                    return nil
                }

                service.informationDidUpdated()
                return service.compare(oldFee: oldFee, newFee: newFee)
            }
            .first()
            .handleEvents(receiveSubscription: { [weak provider] _ in
                provider?.updateFees()
            })
            .eraseToAnyPublisher()
    }
}

enum InformationRelevanceServiceUpdateResult {
    case ok
    case feeWasIncreased
}
