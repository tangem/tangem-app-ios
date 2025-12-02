//
//  TangemPayMainHeaderSubtitleProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemVisa
import TangemFoundation

struct TangemPayMainHeaderSubtitleProvider {
    private let tokenItem: TokenItem
    private let balanceSubject: CurrentValueSubject<LoadingResult<TangemPayBalance, Error>?, Never>
    private let balanceFormatter = BalanceFormatter()

    init(
        tokenItem: TokenItem,
        balanceSubject: CurrentValueSubject<LoadingResult<TangemPayBalance, Error>?, Never>
    ) {
        self.tokenItem = tokenItem
        self.balanceSubject = balanceSubject
    }
}

// MARK: - MainHeaderBalanceProvider

extension TangemPayMainHeaderSubtitleProvider: MainHeaderSubtitleProvider {
    var containsSensitiveInfo: Bool { true }

    var isLoadingPublisher: AnyPublisher<Bool, Never> {
        balanceSubject
            .map { $0?.isLoading ?? true }
            .eraseToAnyPublisher()
    }

    var subtitlePublisher: AnyPublisher<MainHeaderSubtitleInfo, Never> {
        balanceSubject
            .map { mapToMainHeaderSubtitleInfo(balance: $0) }
            .eraseToAnyPublisher()
    }
}

// MARK: - TangemPayMainHeaderSubtitleProvider

private extension TangemPayMainHeaderSubtitleProvider {
    func mapToMainHeaderSubtitleInfo(balance: LoadingResult<TangemPayBalance, Error>?) -> MainHeaderSubtitleInfo {
        switch balance {
        case .none, .loading: return .empty
        case .failure:
            return .init(messages: [BalanceFormatter.defaultEmptyBalanceString], formattingOption: .default)
        case .success(let balance):
            let message = balanceFormatter.formatCryptoBalance(
                balance.crypto.balance,
                currencyCode: tokenItem.currencySymbol
            )
            return .init(messages: [message], formattingOption: .default)
        }
    }
}
