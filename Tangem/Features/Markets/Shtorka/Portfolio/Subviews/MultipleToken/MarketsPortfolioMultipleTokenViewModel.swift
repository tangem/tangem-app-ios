//
//  MarketsPortfolioMultipleTokenViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation
import TangemLocalization
import struct SwiftUI.Color
import TangemUI
import TangemAssets

final class MarketsPortfolioMultipleTokenViewModel: ObservableObject {
    typealias Text = SensitiveText.TextType
    typealias BalanceState = MarketsPortfolioTokenBalanceState

    typealias TokenBalancePublisher = AnyPublisher<TokenBalanceType, Never>
    typealias Action = () -> Void

    @Published private(set) var cryptoBalanceState: BalanceState = .loading
    @Published private(set) var fiatBalanceState: BalanceState = .loading

    var tokenName: String {
        tokenInfo.name
    }

    var tokensCount: String {
        Localization.commonTokensCount(tokenInfo.count)
    }

    var tokenIconInfo: TokenIconInfo {
        tokenInfo.iconInfo
    }

    var tokenIconSetRange: Range<Int> {
        0 ..< min(tokenInfo.count, tokenIconSetMaxCount)
    }

    var balancePublishers: [TokenBalancePublisher] {
        fiatTotalTokenBalancePublishers
    }

    private var tokenCurrencyCode: String {
        tokenInfo.currencyCode
    }

    private let tokenInfo: TokenInfo
    private let fiatTotalTokenBalancePublishers: [TokenBalancePublisher]
    private let cryptoTotalTokenBalancePublishers: [TokenBalancePublisher]
    private let onTapAction: Action

    private let tokenIconSetMaxCount: Int = 3
    private let balanceFormatter = BalanceFormatter()

    init(
        tokenInfo: TokenInfo,
        fiatTotalTokenBalancePublishers: [TokenBalancePublisher],
        cryptoTotalTokenBalancePublishers: [TokenBalancePublisher],
        onTapAction: @escaping Action
    ) {
        self.tokenInfo = tokenInfo
        self.fiatTotalTokenBalancePublishers = fiatTotalTokenBalancePublishers
        self.cryptoTotalTokenBalancePublishers = cryptoTotalTokenBalancePublishers
        self.onTapAction = onTapAction

        bind()
    }
}

// MARK: - Internal methods

extension MarketsPortfolioMultipleTokenViewModel {
    func onTap() {
        onTapAction()
    }

    func tokenIconSetOffset(totalWidth: CGFloat, iconWidth: CGFloat) -> CGFloat {
        CGFloat(totalWidth - iconWidth) / CGFloat(tokenIconSetMaxCount - 1)
    }
}

// MARK: - Binding

private extension MarketsPortfolioMultipleTokenViewModel {
    func bind() {
        fiatTotalTokenBalancePublishers
            .combineLatest()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .map { viewModel, balanceTypes in
                viewModel.fiatBalanceState(balanceTypes: balanceTypes)
            }
            .assign(to: &$fiatBalanceState)

        cryptoTotalTokenBalancePublishers
            .combineLatest()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .compactMap { viewModel, balanceTypes in
                viewModel.cryptoBalanceState(
                    balanceTypes: balanceTypes,
                    currencyCode: viewModel.tokenCurrencyCode
                )
            }
            .assign(to: &$cryptoBalanceState)
    }
}

// MARK: - Crypto balance

private extension MarketsPortfolioMultipleTokenViewModel {
    func cryptoBalanceState(balanceTypes: [TokenBalanceType], currencyCode: String) -> BalanceState {
        let hasLoadingBalances = hasLoadingBalances(balanceTypes: balanceTypes)
        let hasBalance = hasBalance(balanceTypes: balanceTypes)

        if hasLoadingBalances {
            if hasBalance {
                let formattedBalance = formattedCryptoBalance(balanceTypes, currencyCode: currencyCode)
                let attributedBalance = attributedCryptoBalance(formattedBalance)
                return .loadingCached(attributedBalance)
            } else {
                return .loading
            }
        } else {
            if hasBalance {
                let formattedBalance = formattedCryptoBalance(balanceTypes, currencyCode: currencyCode)
                let attributedBalance = attributedCryptoBalance(formattedBalance)
                return .loaded(attributedBalance)
            }

            let allBalancesFailed = allBalancesFailed(balanceTypes: balanceTypes)

            if allBalancesFailed {
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

    func formattedCryptoBalance(_ balanceTypes: [TokenBalanceType], currencyCode: String) -> String {
        let balance = totalBalance(balanceTypes: balanceTypes)
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

private extension MarketsPortfolioMultipleTokenViewModel {
    func fiatBalanceState(balanceTypes: [TokenBalanceType]) -> BalanceState {
        let hasLoadingBalances = hasLoadingBalances(balanceTypes: balanceTypes)
        let hasBalance = hasBalance(balanceTypes: balanceTypes)

        if hasLoadingBalances {
            if hasBalance {
                let formattedBalance = formattedFiatBalance(balanceTypes)
                let attributedBalance = attributedFiatBalance(formattedBalance)
                return .loadingCached(attributedBalance)
            } else {
                return .loading
            }
        } else {
            if hasBalance {
                let formattedBalance = formattedFiatBalance(balanceTypes)
                let attributedBalance = attributedFiatBalance(formattedBalance)
                return .loaded(attributedBalance)
            } else {
                let formattedBalance = balanceFormatter.formatFiatBalance(nil)
                let attributedBalance = attributedCryptoBalance(formattedBalance)
                return .failed(attributedBalance)
            }
        }
    }

    func formattedFiatBalance(_ balanceTypes: [TokenBalanceType]) -> String {
        let balance = totalBalance(balanceTypes: balanceTypes)
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

private extension MarketsPortfolioMultipleTokenViewModel {
    func hasLoadingBalances(balanceTypes: [TokenBalanceType]) -> Bool {
        balanceTypes.contains { $0.isLoading }
    }

    func allBalancesFailed(balanceTypes: [TokenBalanceType]) -> Bool {
        balanceTypes.allSatisfy { $0.isFailure }
    }

    func totalBalance(balanceTypes: [TokenBalanceType]) -> Decimal {
        balanceTypes.reduce(.zero) { total, balanceType in
            let balance = balanceType.value ?? .zero
            return total + balance
        }
    }

    func hasBalance(balanceTypes: [TokenBalanceType]) -> Bool {
        balanceTypes.contains(where: hasBalance)
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

extension MarketsPortfolioMultipleTokenViewModel {
    struct TokenInfo {
        let name: String
        let count: Int
        let currencyCode: String
        let iconInfo: TokenIconInfo
    }
}
