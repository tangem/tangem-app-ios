//
//  MarketsPortfolioTokenListRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemLocalization
import struct SwiftUI.Color
import struct SwiftUI.Font
import TangemUI
import TangemAssets

final class MarketsPortfolioTokenListRowViewModel: ObservableObject {
    typealias Text = SensitiveText.TextType
    typealias BalanceState = MarketsPortfolioTokenBalanceState

    typealias TokenBalancePublisher = AnyPublisher<TokenBalanceType, Never>

    @Published private(set) var cryptoBalanceState: BalanceState = .loading
    @Published private(set) var fiatBalanceState: BalanceState = .loading

    let isNoAddress: Bool

    var noAddressText: String {
        Localization.commonNoAddress
    }

    var tokenName: String {
        tokenInfo.name
    }

    var networkName: String {
        tokenInfo.networkName
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
    private let fiatTotalTokenBalancePublisher: TokenBalancePublisher
    private let cryptoTotalTokenBalancePublisher: TokenBalancePublisher

    private let balanceFormatter = BalanceFormatter()

    init(
        tokenInfo: TokenInfo,
        fiatTotalTokenBalancePublisher: TokenBalancePublisher,
        cryptoTotalTokenBalancePublisher: TokenBalancePublisher
    ) {
        self.tokenInfo = tokenInfo
        self.fiatTotalTokenBalancePublisher = fiatTotalTokenBalancePublisher
        self.cryptoTotalTokenBalancePublisher = cryptoTotalTokenBalancePublisher
        isNoAddress = false

        bind()
    }

    init(noAddressTokenInfo tokenInfo: TokenInfo) {
        self.tokenInfo = tokenInfo
        fiatTotalTokenBalancePublisher = Empty<TokenBalanceType, Never>().eraseToAnyPublisher()
        cryptoTotalTokenBalancePublisher = Empty<TokenBalanceType, Never>().eraseToAnyPublisher()
        isNoAddress = true
    }
}

// MARK: - Binding

private extension MarketsPortfolioTokenListRowViewModel {
    func bind() {
        fiatTotalTokenBalancePublisher
            .withWeakCaptureOf(self)
            .map { viewModel, balanceType in
                viewModel.fiatBalanceState(balanceType: balanceType)
            }
            .receiveOnMain()
            .assign(to: &$fiatBalanceState)

        cryptoTotalTokenBalancePublisher
            .withWeakCaptureOf(self)
            .compactMap { viewModel, balanceType in
                viewModel.cryptoBalanceState(
                    balanceType: balanceType,
                    currencyCode: viewModel.tokenCurrencyCode
                )
            }
            .receiveOnMain()
            .assign(to: &$cryptoBalanceState)
    }
}

// MARK: - Crypto balance

private extension MarketsPortfolioTokenListRowViewModel {
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
        let attributedBalance = AttributedBalanceFormatter.format(
            balance,
            font: Font.Tangem.Caption12.semibold,
            integerColor: .Tangem.Text.Neutral.secondary,
            fractionalColor: .Tangem.Text.Neutral.secondary
        )
        return .attributed(attributedBalance)
    }

    func attributedUnreachableBalance() -> Text {
        var attributed = AttributedString(Localization.commonUnreachable)
        attributed.setFontStyle(Font.Tangem.Caption12.semibold)
        attributed.foregroundColor = .Tangem.Text.Status.attention
        return .attributed(attributed)
    }
}

// MARK: - Fiat balance

private extension MarketsPortfolioTokenListRowViewModel {
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
                let attributedBalance = attributedCryptoBalance(formattedBalance)
                return .failed(attributedBalance)
            }
        }
    }

    func formattedFiatBalance(_ balanceType: TokenBalanceType) -> String {
        let balance = totalBalance(balanceType: balanceType)
        return balanceFormatter.formatFiatBalance(balance)
    }

    func attributedFiatBalance(_ balance: String) -> Text {
        let attributedBalance = AttributedBalanceFormatter.format(
            balance,
            font: Font.Tangem.Body16.medium,
            integerColor: .Tangem.Text.Neutral.primary,
            fractionalColor: .Tangem.Text.Neutral.secondary
        )
        return .attributed(attributedBalance)
    }
}

// MARK: - Private methods

private extension MarketsPortfolioTokenListRowViewModel {
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

extension MarketsPortfolioTokenListRowViewModel {
    struct TokenInfo {
        let name: String
        let networkName: String
        let currencyCode: String
        let iconInfo: TokenIconInfo
    }
}
