//
//  SendFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

protocol SendFeeProviderInput: AnyObject {
    var cryptoAmountPublisher: AnyPublisher<Decimal, Never> { get }
    var destinationAddressPublisher: AnyPublisher<String, Never> { get }
}

protocol SendFeeProvider {
    // Default supported fee options from provider
    // var feeOptions: [FeeOption] { get }
    // var feeTokenItem: TokenItem { get }

    var fees: LoadableFees { get }
    var feesPublisher: AnyPublisher<LoadableFees, Never> { get }

    func updateFees()
}

extension SendFeeProvider {
    var feesHasVariants: AnyPublisher<Bool, Never> {
        feesPublisher
            .filter { !$0.wrapToLoadingResult().isLoading }
            .map { fees in
                fees.hasMultipleFeeOptions
            }
            .eraseToAnyPublisher()
    }

//    func mapToMarketSendFee(fee: LoadingResult<BSDKFee, any Error>) -> SendFee {
//        switch fee {
//        case .success(let fee):
//            return SendFee(option: .market, tokenItem: feeTokenItem, value: .success(fee))
//        case .loading:
//            return SendFee(option: .market, tokenItem: feeTokenItem, value: .loading)
//        case .failure(let error):
//            return SendFee(option: .market, tokenItem: feeTokenItem, value: .failure(error))
//        }
//    }
//
//    func mapToSendFees(fees: LoadingResult<[BSDKFee], any Error>) -> [SendFee] {
//        switch fees {
//        case .success(let fees):
//            return loadedFees(fees: fees)
//        case .loading:
//            return loadingFees()
//        case .failure(let error):
//            return failureFees(error: error)
//        }
//    }
//
//    func loadingFees() -> [SendFee] {
//        SendFeeConverter.mapToLoadingSendFees(options: feeOptions, feeTokenItem: feeTokenItem)
//    }
//
//    func failureFees(error: any Error) -> [SendFee] {
//        SendFeeConverter.mapToFailureSendFees(options: feeOptions, feeTokenItem: feeTokenItem, error: error)
//    }
//
//    func loadedFees(fees: [BSDKFee]) -> [SendFee] {
//        SendFeeConverter.mapToSendFees(fees: fees, feeTokenItem: feeTokenItem)
//    }
}
