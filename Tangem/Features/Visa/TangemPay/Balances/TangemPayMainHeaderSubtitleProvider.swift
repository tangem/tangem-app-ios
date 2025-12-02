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
    private let balanceSubject: CurrentValueSubject<LoadingResult<TangemPayBalance, Error>, Never>
    private let balanceFormatter = BalanceFormatter()

    init(balanceSubject: CurrentValueSubject<LoadingResult<TangemPayBalance, Error>, Never>) {
        self.balanceSubject = balanceSubject
    }
}

// MARK: - MainHeaderBalanceProvider

extension TangemPayMainHeaderSubtitleProvider: MainHeaderSubtitleProvider {
    var containsSensitiveInfo: Bool { true }

    var isLoadingPublisher: AnyPublisher<Bool, Never> {
        balanceSubject
            .map(\.isLoading)
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
    func mapToMainHeaderSubtitleInfo(balance: LoadingResult<TangemPayBalance, Error>) -> MainHeaderSubtitleInfo {
        switch balance {
        case .loading, .failure: return .empty
        case .success(let balance):
            // We use `formatCryptoBalance` to save `currencyCode` as is
            let message = balanceFormatter.formatCryptoBalance(
                balance.crypto.balance,
                currencyCode: TangemPayUtilities.usdcTokenItem.currencySymbol
            )
            return .init(messages: [message], formattingOption: .default)
        }
    }
}
