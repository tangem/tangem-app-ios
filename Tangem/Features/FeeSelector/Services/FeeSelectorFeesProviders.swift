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
    var suggestedFee: LoadableTokenFee { get }
    var suggestedFeePublisher: AnyPublisher<LoadableTokenFee, Never> { get }
}
