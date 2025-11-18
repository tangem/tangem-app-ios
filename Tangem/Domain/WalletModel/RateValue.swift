//
//  RateValue.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum RateValue<Quote> {
    case custom
    case loading(cached: Quote?)
    case failure(cached: Quote?)
    case loaded(quote: Quote)

    var quote: Quote? {
        switch self {
        case .custom:
            return nil
        case .loading(let cached),
             .failure(let cached):
            return cached
        case .loaded(let quote):
            return quote
        }
    }
}

// MARK: - Equatable protocol conformance

extension RateValue: Equatable where Quote: Equatable {}

// MARK: - Hashable protocol conformance

extension RateValue: Hashable where Quote: Hashable {}
