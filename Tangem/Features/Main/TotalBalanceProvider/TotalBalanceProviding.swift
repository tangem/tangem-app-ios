//
//  TotalBalanceProviding.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import Foundation

protocol TotalBalanceProviding {
    var totalBalance: TotalBalanceState { get }
    var totalBalancePublisher: AnyPublisher<TotalBalanceState, Never> { get }
}

// MARK: - TotalBalanceState

enum TotalBalanceState: Hashable {
    case empty
    case loading(cached: Decimal?)
    case failed(cached: Decimal?, failedItems: [TokenItem])
    case loaded(balance: Decimal)

    var isLoading: Bool {
        switch self {
        case .loading: true
        default: false
        }
    }

    var isLoaded: Bool {
        switch self {
        case .loaded: true
        default: false
        }
    }

    var hasPositiveBalance: Bool {
        let balance: Decimal = switch self {
        case .loaded(let balance): balance
        default: 0
        }
        return balance > 0
    }
}

// MARK: - CustomStringConvertible

extension TotalBalanceState: CustomStringConvertible {
    var description: String {
        switch self {
        case .empty: "Empty"
        case .loading: "Loading"
        case .failed: "Failed"
        case .loaded: "Loaded"
        }
    }
}
