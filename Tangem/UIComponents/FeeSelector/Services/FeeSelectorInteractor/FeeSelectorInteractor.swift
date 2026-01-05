//
//  CommonFeeSelectorInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

protocol FeeSelectorInteractorInput {
    var selectedFee: SendFee { get }
    var selectedFeePublisher: AnyPublisher<SendFee, Never> { get }
}

protocol FeeSelectorInteractor {
    var selectedFee: SendFee { get }
    var selectedFeePublisher: AnyPublisher<SendFee, Never> { get }

    // Has to contains all supported fee. E.g .custom or suggested
    var fees: [SendFee] { get }
    var feesPublisher: AnyPublisher<[SendFee], Never> { get }
}

extension FeeSelectorInteractor {
    var autoupdatedSuggestedFee: AnyPublisher<SendFee, Never> {
        feesPublisher.compactMap { fees -> SendFee? in
            // Custom don't supoort autoupdate
            var fees = fees.filter { $0.option != .custom }

            // If we have one fee which is failure
            if let failureFee = fees.first(where: { $0.value.isFailure }) {
                return failureFee
            }

            // Have loading and non selected
            if let loadingFee = fees.first(where: { $0.value.isLoading }), selectedFee.value.value == nil {
                return loadingFee
            }

            // All good. Fee just updated
            if let successFee = fees.first(where: { $0.option == selectedFee.option }) {
                return successFee
            }

            // First to select the market fee
            return fees.first(where: { $0.option == .market })
        }
        .removeDuplicates()
        .eraseToAnyPublisher()
    }
}
