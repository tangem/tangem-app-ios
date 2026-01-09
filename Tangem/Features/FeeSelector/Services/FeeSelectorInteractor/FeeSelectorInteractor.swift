//
//  FeeSelectorInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

protocol FeeSelectorInteractorInput: AnyObject {
    var selectedFee: TokenFee { get }
    var selectedFeePublisher: AnyPublisher<TokenFee, Never> { get }
}

protocol FeeSelectorInteractor: FeeSelectorFeesDataProvider, FeeSelectorTokensDataProvider {}
//
//extension FeeSelectorInteractor {
//    var autoupdatedSuggestedFee: AnyPublisher<TokenFee, Never> {
//        feesPublisher.compactMap { fees -> TokenFee? in
//            // Custom don't support autoupdate
//            let fees = fees.filter { $0.option != .custom }
//
//            // If we have one fee which is failure
//            if let failureFee = fees.first(where: { $0.value.isFailure }) {
//                return failureFee
//            }
//
//            let hasSelected = selectedFee?.value.value == nil
//
//            // Have loading and non selected
//            if let loadingFee = fees.first(where: { $0.value.isLoading }), !hasSelected {
//                return loadingFee
//            }
//
//            let selectedFeeOption = hasSelected ? selectedFee?.option : .market
//
//            // All good. Fee just updated
//            if let successFee = fees.first(where: { $0.option == selectedFeeOption }) {
//                return successFee
//            }
//
//            // First to select the market fee
//            return fees.first(where: { $0.option == .market })
//        }
//        .removeDuplicates()
//        .eraseToAnyPublisher()
//    }
//}
