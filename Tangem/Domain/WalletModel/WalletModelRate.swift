//
//  WalletModelRate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Rate

enum WalletModelRate: Hashable {
    case custom
    case loading(cached: TokenQuote?)
    case failure(cached: TokenQuote?)
    case loaded(TokenQuote)

    var quote: TokenQuote? {
        switch self {
        case .custom: nil
        case .loading(let cached), .failure(let cached): cached
        case .loaded(let quote): quote
        }
    }
}
