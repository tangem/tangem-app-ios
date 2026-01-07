//
//  TokenFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

protocol StatableTokenFeeProvider: AnyObject {
    var supportingFeeOption: [FeeOption] { get }
    var feeTokenItem: TokenItem { get }

    var loadingFees: LoadingResult<[BSDKFee], any Error> { get }
    var loadingFeesPublisher: AnyPublisher<LoadingResult<[BSDKFee], any Error>, Never> { get }
}

extension StatableTokenFeeProvider {
    func mapToFees(loadingFees fees: LoadingResult<[BSDKFee], any Error>) -> [TokenFee] {
        switch fees {
        case .loading:
            TokenFeeConverter.mapToLoadingSendFees(options: supportingFeeOption, feeTokenItem: feeTokenItem)
        case .failure(let error):
            TokenFeeConverter.mapToFailureSendFees(options: supportingFeeOption, feeTokenItem: feeTokenItem, error: error)
        case .success(let loadedFees):
            TokenFeeConverter
                .mapToSendFees(fees: loadedFees, feeTokenItem: feeTokenItem)
                .filter { supportingFeeOption.contains($0.option) }
        }
    }
}

/// Wrappers
/// 1. ExpressFeeProvider (add autoselect to as ExpressFee to use it in transaction)
/// 2. SendFeeProvider (add autoupdate fee and push to output - SendModel)
/// 3. SendWithSwapFeeProvider (Has switcher to select between two providers)
/// 4. StakingFeeProvider (Basically don't support update. Can be simple provider. Without external changes)
/// 5. Sell, NFT (Can be use only only SendFeeProvider if possible)
extension TokenFeeProvider where Self: StatableTokenFeeProvider {
    var fees: [TokenFee] {
        mapToFees(loadingFees: loadingFees)
    }

    var feesPublisher: AnyPublisher<[TokenFee], Never> {
        loadingFeesPublisher
            .withWeakCaptureOf(self)
            .map { $0.mapToFees(loadingFees: $1) }
            .eraseToAnyPublisher()
    }
}

/// Has state
/// created with SendingTokenItem
protocol TokenFeeProvider {
    var fees: [TokenFee] { get }
    var feesPublisher: AnyPublisher<[TokenFee], Never> { get }
}

protocol SendFeeProvider: TokenFeeProvider {
    func updateFees()
}

protocol SetupableSendFeeProvider: SendFeeProvider {
    func setup(input: any SendFeeProviderInput)
}

protocol UpdatableSimpleTokenFeeProvider: TokenFeeProvider {
    var tokenItems: [TokenItem] { get }
    var tokenItemsPublisher: AnyPublisher<[TokenItem], Never> { get }

    func userDidSelectTokenItem(_ tokenItem: TokenItem)
}
