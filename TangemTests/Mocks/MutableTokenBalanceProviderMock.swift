//
//  MutableTokenBalanceProviderMock.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
@testable import Tangem

final class MutableTokenBalanceProviderMock: TokenBalanceProvider {
    private let balanceSubject: CurrentValueSubject<TokenBalanceType, Never>

    var balanceType: TokenBalanceType {
        get { balanceSubject.value }
        set { balanceSubject.send(newValue) }
    }

    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> {
        balanceSubject.eraseToAnyPublisher()
    }

    var formattedBalanceType: FormattedTokenBalanceType {
        switch balanceType {
        case .loaded(let balance):
            return .loaded(balance.description)
        case .loading(let cached):
            if let cached = cached {
                return .loading(.cache(.init(balance: cached.balance.description, date: cached.date)))
            } else {
                return .loading(.empty(""))
            }
        case .failure(let cached):
            if let cached = cached {
                return .failure(.cache(.init(balance: cached.balance.description, date: cached.date)))
            } else {
                return .failure(.empty(""))
            }
        case .empty:
            return .loading(.empty(""))
        }
    }

    var formattedBalanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        balanceTypePublisher
            .map { balanceType in
                switch balanceType {
                case .loaded(let balance):
                    return .loaded(balance.description)
                case .loading(let cached):
                    if let cached = cached {
                        return .loading(.cache(.init(balance: cached.balance.description, date: cached.date)))
                    } else {
                        return .loading(.empty(""))
                    }
                case .failure(let cached):
                    if let cached = cached {
                        return .failure(.cache(.init(balance: cached.balance.description, date: cached.date)))
                    } else {
                        return .failure(.empty(""))
                    }
                case .empty:
                    return .loading(.empty(""))
                }
            }
            .eraseToAnyPublisher()
    }

    init(initialState: TokenBalanceType) {
        balanceSubject = CurrentValueSubject(initialState)
    }

    convenience init(balance: Decimal) {
        self.init(initialState: .loaded(balance))
    }

    func sendUpdate() {
        balanceSubject.send(balanceSubject.value)
    }

    func updateBalance(_ newState: TokenBalanceType) {
        balanceType = newState
    }
}
