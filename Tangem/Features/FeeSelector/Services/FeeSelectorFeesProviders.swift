//
//  FeeSelectorFeesProviders.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

// MARK: - Custom fees

protocol FeeSelectorSuggestedFeeProvider {
    var suggestedFee: TokenFee { get }
    var suggestedFeePublisher: AnyPublisher<TokenFee, Never> { get }
}
