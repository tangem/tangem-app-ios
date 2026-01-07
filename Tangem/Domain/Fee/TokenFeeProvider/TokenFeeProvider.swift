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

protocol StatableTokenFeeProvider {
    var fees: LoadingResult<[BSDKFee], any Error> { get }
}

// created with SendingTokenItem
protocol SimpleTokenFeeProvider {
    // Has state

    var fees: [TokenFee] { get }
    var feesPublisher: AnyPublisher<[TokenFee], Never> { get }
}

protocol SendFeeProvider: SimpleTokenFeeProvider {
    func updateFees()
}

protocol ExpressSimpleTokenFeeProvider: SimpleTokenFeeProvider {
    func updateFees(amount: Decimal, destination: String)
}

protocol UpdatableSimpleTokenFeeProvider: SimpleTokenFeeProvider {
    var tokenItems: [TokenItem] { get }
    var tokenItemsPublisher: AnyPublisher<[TokenItem], Never> { get }

    func userDidSelectTokenItem(_ tokenItem: TokenItem)
}

// Available `TokenItems` to selector in other provider.

// Wrappers
// 1. ExpressFeeProvider (add autoselect to as ExpressFee to use it in transaction)
// 2. SendFeeProvider (add autoupdate fee and push to output - SendModel)
// 3. SendWithSwapFeeProvider (Has switcher to select between two providers)
// 4. StakingFeeProvider (Basically don't support update. Can be simple provider. Without external changes)
// 5. Sell, NFT (Can be use only only SendFeeProvider if possible)

protocol TokenFeeProvider: FeeSelectorFeesProvider {
    var fees: [TokenFee] { get }
    var feesPublisher: AnyPublisher<[TokenFee], Never> { get }

    func reloadFees(request: TokenFeeProviderFeeRequest) async
}

extension TokenFeeProvider {
    func reloadFees(request: TokenFeeProviderFeeRequest) {
        Task { await reloadFees(request: request) }
    }
}

struct TokenFeeProviderFeeRequest {
    let amount: Decimal
    let destination: String
    /// Sending token item
    let tokenItem: TokenItem
}
