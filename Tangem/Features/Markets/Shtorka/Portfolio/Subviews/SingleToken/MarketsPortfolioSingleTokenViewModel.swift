//
//  MarketsPortfolioSingleTokenViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemLocalization
import struct SwiftUI.Color
import TangemUI
import TangemAssets

final class MarketsPortfolioSingleTokenViewModel: ObservableObject {
    typealias Text = SensitiveText.TextType
    typealias BalanceState = MarketsPortfolioTokenBalanceState

    typealias TokenBalancePublisher = AnyPublisher<TokenBalanceType, Never>
    typealias RatePublisher = AnyPublisher<WalletModelRate, Never>
    typealias Action = () -> Void

    @Published private(set) var priceWithChangeState: PriceWithChangeState = .loading
    @Published private(set) var cryptoBalanceState: BalanceState = .loading
    @Published private(set) var fiatBalanceState: BalanceState = .loading

    var tokenName: String {
        tokenInfo.name
    }

    var tokenIconInfo: TokenIconInfo {
        tokenInfo.iconInfo
    }

    var balancePublisher: TokenBalancePublisher {
        fiatTotalTokenBalancePublisher
    }

    private var tokenCurrencyCode: String {
        tokenInfo.currencyCode
    }

    private let tokenInfo: TokenInfo
    private let ratePublisher: RatePublisher
    private let fiatTotalTokenBalancePublisher: TokenBalancePublisher
    private let cryptoTotalTokenBalancePublisher: TokenBalancePublisher
    private let onTapAction: Action

    private let priceFormatter = TokenItemPriceFormatter()
    private let priceChangeUtility = PriceChangeUtility()
    private let balanceFormatter = BalanceFormatter()

    init(
        tokenInfo: TokenInfo,
        ratePublisher: RatePublisher,
        fiatTotalTokenBalancePublisher: TokenBalancePublisher,
        cryptoTotalTokenBalancePublisher: TokenBalancePublisher,
        onTapAction: @escaping Action
    ) {
        self.tokenInfo = tokenInfo
        self.ratePublisher = ratePublisher
        self.fiatTotalTokenBalancePublisher = fiatTotalTokenBalancePublisher
        self.cryptoTotalTokenBalancePublisher = cryptoTotalTokenBalancePublisher
        self.onTapAction = onTapAction

        bind()
    }
}

// MARK: - Internal methods

extension MarketsPortfolioSingleTokenViewModel {
    func onTap() {
        onTapAction()
    }
}

// MARK: - Binding

private extension MarketsPortfolioSingleTokenViewModel {
    func bind() {
        ratePublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .map { viewModel, rate in
                viewModel.priceWithChangeState(rate: rate)
            }
            .assign(to: &$priceWithChangeState)

        fiatTotalTokenBalancePublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .map { viewModel, balanceType in
                viewModel.fiatBalanceState(balanceType: balanceType)
            }
            .assign(to: &$fiatBalanceState)

        cryptoTotalTokenBalancePublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .compactMap { viewModel, balanceType in
                viewModel.cryptoBalanceState(
                    balanceType: balanceType,
                    currencyCode: viewModel.tokenCurrencyCode
                )
            }
            .assign(to: &$cryptoBalanceState)
    }
}

// MARK: - Price with change

private extension MarketsPortfolioSingleTokenViewModel {
    func priceWithChangeState(rate: WalletModelRate) -> PriceWithChangeState {
        switch rate {
        case .loading(.none):
            return .loading
        case .loading(.some(let quote)), .failure(.some(let quote)), .loaded(let quote):
            return PriceWithChangeState(
                priceState: priceState(quote: quote),
                changeState: priceChangeState(quote: quote)
            )
        case .custom, .failure(.none):
            return PriceWithChangeState(
                priceState: .noData,
                changeState: .empty
            )
        }
    }

    func priceState(quote: TokenQuote) -> LoadableTextView.State {
        .loaded(text: priceFormatter.formatPrice(quote.price))
    }

    func priceChangeState(quote: TokenQuote) -> PriceChangeView.State {
        priceChangeUtility.convertToPriceChangeState(changePercent: quote.priceChange24h)
    }
}

// MARK: - Crypto balance

private extension MarketsPortfolioSingleTokenViewModel {
    func cryptoBalanceState(balanceType: TokenBalanceType, currencyCode: String) -> BalanceState {
        let hasLoadingBalance = hasLoadingBalance(balanceType: balanceType)
        let hasBalance = hasBalance(balanceType: balanceType)

        if hasLoadingBalance {
            if hasBalance {
                let formattedBalance = formattedCryptoBalance(balanceType, currencyCode: currencyCode)
                let attributedBalance = attributedCryptoBalance(formattedBalance)
                return .loadingCached(attributedBalance)
            } else {
                return .loading
            }
        } else {
            if hasBalance {
                let formattedBalance = formattedCryptoBalance(balanceType, currencyCode: currencyCode)
                let attributedBalance = attributedCryptoBalance(formattedBalance)
                return .loaded(attributedBalance)
            }

            let hasFailedBalance = hasFailedBalance(balanceType: balanceType)

            if hasFailedBalance {
                let attributedBalance = attributedUnreachableBalance()
                let icon = BalanceState.Icon(
                    type: Assets.DesignSystem.attention,
                    color: .Tangem.Graphic.Status.attention,
                    location: .trailing
                )
                return .failed(attributedBalance, icon)
            } else {
                let formattedBalance = balanceFormatter.formatCryptoBalance(nil, currencyCode: currencyCode)
                let attributedBalance = attributedCryptoBalance(formattedBalance)
                return .failed(attributedBalance)
            }
        }
    }

    func formattedCryptoBalance(_ balanceType: TokenBalanceType, currencyCode: String) -> String {
        let balance = totalBalance(balanceType: balanceType)
        return balanceFormatter.formatCryptoBalance(balance, currencyCode: currencyCode)
    }

    func attributedCryptoBalance(_ balance: String) -> Text {
        let attributedBalance = TangemTokenRowBalanceFormatter.formatWithDecimalColoring(
            balance,
            font: .Tangem.Caption12.semibold,
            integerColor: .Tangem.Text.Neutral.secondary,
            decimalColor: .Tangem.Text.Neutral.secondary
        )
        return .attributed(attributedBalance)
    }

    func attributedUnreachableBalance() -> Text {
        var attributed = AttributedString(Localization.commonUnreachable)
        attributed.font = .Tangem.Caption12.semibold
        attributed.foregroundColor = .Tangem.Text.Status.attention
        return .attributed(attributed)
    }
}

// MARK: - Fiat balance

private extension MarketsPortfolioSingleTokenViewModel {
    func fiatBalanceState(balanceType: TokenBalanceType) -> BalanceState {
        let hasLoadingBalance = hasLoadingBalance(balanceType: balanceType)
        let hasBalance = hasBalance(balanceType: balanceType)

        if hasLoadingBalance {
            if hasBalance {
                let formattedBalance = formattedFiatBalance(balanceType)
                let attributedBalance = attributedFiatBalance(formattedBalance)
                return .loadingCached(attributedBalance)
            } else {
                return .loading
            }
        } else {
            if hasBalance {
                let formattedBalance = formattedFiatBalance(balanceType)
                let attributedBalance = attributedFiatBalance(formattedBalance)
                let hasFailedBalance = hasFailedBalance(balanceType: balanceType)

                if hasFailedBalance {
                    let icon = BalanceState.Icon(
                        type: Assets.DesignSystem.errorSync,
                        color: .Tangem.Graphic.Neutral.secondary,
                        location: .leading
                    )
                    return .failed(attributedBalance, icon)
                } else {
                    return .loaded(attributedBalance)
                }
            } else {
                let formattedBalance = balanceFormatter.formatFiatBalance(nil)
                let attributedBalance = attributedFiatBalance(formattedBalance)
                return .failed(attributedBalance)
            }
        }
    }

    func formattedFiatBalance(_ balanceType: TokenBalanceType) -> String {
        let balance = totalBalance(balanceType: balanceType)
        return balanceFormatter.formatFiatBalance(balance)
    }

    func attributedFiatBalance(_ balance: String) -> Text {
        let attributedBalance = TangemTokenRowBalanceFormatter.formatWithDecimalColoring(
            balance,
            font: .Tangem.Body16.medium,
            integerColor: .Tangem.Text.Neutral.primary,
            decimalColor: .Tangem.Text.Neutral.secondary
        )
        return .attributed(attributedBalance)
    }
}

// MARK: - Private methods

private extension MarketsPortfolioSingleTokenViewModel {
    func hasLoadingBalance(balanceType: TokenBalanceType) -> Bool {
        balanceType.isLoading
    }

    func hasFailedBalance(balanceType: TokenBalanceType) -> Bool {
        balanceType.isFailure
    }

    func totalBalance(balanceType: TokenBalanceType) -> Decimal {
        balanceType.value ?? .zero
    }

    func hasBalance(balanceType: TokenBalanceType) -> Bool {
        switch balanceType {
        case .loaded: true
        case .loading(let cached): cached != nil
        case .failure(let cached): cached != nil
        case .empty(let reason): reason.isNoAccount
        }
    }
}

// MARK: - Types

extension MarketsPortfolioSingleTokenViewModel {
    struct TokenInfo {
        let name: String
        let currencyCode: String
        let iconInfo: TokenIconInfo
    }

    struct PriceWithChangeState {
        let priceState: LoadableTextView.State
        let changeState: PriceChangeView.State

        static let loading = PriceWithChangeState(
            priceState: .loading,
            changeState: .loading
        )
    }
}
