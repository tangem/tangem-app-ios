//
//  TokenItemViewModel+TokenRow.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI
import TangemAssets
import TangemAccessibilityIdentifiers
import TangemLocalization

extension TokenItemViewModel {
    var tokenRowContent: TokenRow.Content {
        let iconInfo = TokenIconInfo(
            name: name,
            blockchainIconAsset: blockchainIconAsset,
            imageURL: imageURL,
            isCustom: isCustom,
            customTokenColor: customTokenColor
        )

        if hasError {
            return .note(
                icon: iconInfo,
                title: name,
                quote: quote,
                priceChange: priceChange,
                text: errorMessage ?? "",
                onTap: { [weak self] in self?.tapAction() }
            )
        }

        return .balance(
            icon: TokenRow.Icon(iconInfo, isGrayscale: hasMonochromeIcon),
            title: name,
            titleAccessory: titleAccessory,
            quote: quote,
            priceChange: priceChange,
            balance: TokenRow.Balance(fiat: fiatBalance, crypto: cryptoBalance),
            indicator: balanceIndicator,
            bubble: messageBubbleModel,
            onTap: { [weak self] in self?.tapAction() }
        )
    }

    var tokenRowAccessibilityIdentifiers: TokenRow.AccessibilityIdentifiers {
        TokenRow.AccessibilityIdentifiers(
            name: MainAccessibilityIdentifiers.tokenTitle,
            fiatBalance: MainAccessibilityIdentifiers.tokenBalance(for: name),
            titleAccessory: MainAccessibilityIdentifiers.tokenItemEarnBadge
        )
    }
}

// MARK: - Private

private extension TokenItemViewModel {
    var messageBubbleModel: TokenRowMessageBubble.Model? {
        switch messageBubble {
        case .jointOperationAwaitingSignature:
            TokenRowMessageBubble.Model(
                text: Localization.jointAccountPendingTransactionMessage,
                variant: .warning,
                icon: DesignSystem.Icons.Clock.regular16,
                trailingAccessory: .chevron,
                onTap: { [weak self] in self?.didTapMessageBubble() }
            )

        case .none:
            nil
        }
    }

    var titleAccessory: TokenRowTitleAccessory.Model? {
        switch leadingBadge {
        case .pendingTransaction:
            .pending()

        case .rewards(let info):
            .reward(
                TokenRowTitleAccessory.Model.Reward(
                    label: rewardString(info: info),
                    accent: .staking,
                    isActive: info.isActive,
                    isUpdating: info.isUpdating
                )
            )

        case .none:
            nil
        }
    }

    var balanceIndicator: TokenRow.BalanceIndicator? {
        switch trailingBadge {
        case .isApproveNeeded: .approveNeeded
        case .none: nil
        }
    }

    var quote: String? {
        switch tokenPrice {
        case .loaded(let text), .loadingCached(let text): text
        case .initialized, .noData, .loading: nil
        }
    }

    var priceChange: TokenRowPriceChange? {
        switch priceChangeState {
        case .loaded(let changeType, let text):
            TokenRowPriceChange(value: text, direction: direction(changeType))
        case .loadingCached(let changeType, let text):
            TokenRowPriceChange(value: text, direction: direction(changeType), isUpdating: true)
        case .initialized, .noData, .empty, .loading:
            nil
        }
    }

    var fiatBalance: TokenRow.Balance.Fiat {
        switch balanceFiat {
        case .loading(.none):
            .loading
        case .loading(.some(let text)):
            .updating(balanceValue(text))
        case .loaded(let text):
            .loaded(balanceValue(text))
        case .failed(let text, let icon):
            .loaded(balanceValue(text), isStale: icon != nil)
        }
    }

    var cryptoBalance: TokenRowValue {
        switch balanceCrypto {
        case .loading(.none):
            .loading
        case .loading(.some(let text)):
            .updating(balanceValue(text))
        case .loaded(let text), .failed(let text, _):
            .loaded(balanceValue(text))
        }
    }

    func direction(_ changeType: PriceChangeView.ChangeType) -> UtilPriceChange.Direction {
        switch changeType {
        case .positive: .positive
        case .neutral: .neutral
        case .negative: .negative
        }
    }

    func balanceValue(_ text: SensitiveText.TextType) -> UtilBalance.Value {
        switch text {
        case .string(let value):
            .string(value)
        case .attributed(let value):
            .attributed(value)
        case .builder(let builder, let sensitive):
            .string(builder(sensitive))
        }
    }

    func rewardString(info: RewardsInfo) -> String {
        let rewardType = switch info.type {
        case .apr: Localization.stakingDetailsApr
        case .apy: Localization.stakingDetailsApy
        }
        return "\(rewardType) \(info.rewardValue)"
    }
}
