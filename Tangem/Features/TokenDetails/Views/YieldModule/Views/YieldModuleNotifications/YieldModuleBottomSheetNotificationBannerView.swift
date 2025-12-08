//
//  YieldModuleBottomSheetNotificationBannerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct YieldModuleBottomSheetNotificationBannerView: View {
    // MARK: - Config

    let params: YieldModuleNotificationBannerParams

    // MARK: - Properties

    private var title: String {
        switch params {
        case .approveNeeded:
            return Localization.yieldModuleApproveNeededNotificationTitle
        case .notEnoughFeeCurrency(let feeCurrencyName, _, _):
            return Localization.yieldModuleUnableToCoverFeeTitle(feeCurrencyName)
        case .feeUnreachable:
            return Localization.yieldModuleNetworkFeeUnreachableNotificationTitle
        case .hasUndepositedAmounts(let amount, let currencySymbol):
            return Localization.yieldModuleDepositErrorNotificationTitle(amount, currencySymbol)
        case .highFees:
            return Localization.yieldModuleHighNetworkFeesNotificationTitle
        }
    }

    private var description: String? {
        switch params {
        case .approveNeeded:
            return Localization.yieldModuleApproveNeededNotificationDescription
        case .notEnoughFeeCurrency(let feeCurrencyName, _, _):
            return Localization.yieldModuleUnableToCoverFeeDescription(feeCurrencyName, "")
        case .feeUnreachable:
            return Localization.yieldModuleNetworkFeeUnreachableNotificationDescription
        case .hasUndepositedAmounts:
            return nil
        case .highFees:
            return Localization.yieldModuleHighNetworkFeesNotificationDescription
        }
    }

    private var buttonConfig: ButtonConfig? {
        var title: String
        var action: () -> Void
        var style: MainButton.Style

        switch params {
        case .approveNeeded(let buttonAction):
            title = Localization.yieldModuleApproveNeededNotificationCta
            action = buttonAction
            style = .primary

        case .notEnoughFeeCurrency(let currencyName, _, let buttonAction):
            title = Localization.commonBuyCurrency(currencyName)
            action = buttonAction
            style = .secondary

        case .feeUnreachable(let buttonAction):
            title = Localization.warningButtonRefresh
            action = buttonAction
            style = .secondary

        case .hasUndepositedAmounts, .highFees:
            return nil
        }

        return ButtonConfig(title: title, action: action, style: style)
    }

    // MARK: - View Body

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                icon
                    .resizable()
                    .frame(size: .init(bothDimensions: 20))

                message
                Spacer()
            }

            button
        }
        .defaultRoundedBackground(with: backgroundColor, verticalPadding: 14)
    }

    // MARK: - Sub Views

    private var backgroundColor: Color {
        switch params {
        case .highFees:
            return Colors.Button.disabled
        default:
            return Colors.Background.action
        }
    }

    private var message: some View {
        VStack(alignment: .leading, spacing: 4) {
            titleView
            descriptionView
        }
    }

    private var icon: Image {
        switch params {
        case .hasUndepositedAmounts, .highFees:
            return Assets.blueCircleWarning.image
        case .approveNeeded, .feeUnreachable:
            return Assets.attention.image
        case .notEnoughFeeCurrency(_, let tokenIcon, _):
            return tokenIcon.image
        }
    }

    private var titleView: some View {
        Text(title)
            .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
    }

    @ViewBuilder
    private var descriptionView: some View {
        if let description {
            Text(description)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
        }
    }

    @ViewBuilder
    private var button: some View {
        if let buttonConfig {
            MainButton(
                title: buttonConfig.title,
                style: buttonConfig.style,
                size: .notification,
                action: buttonConfig.action
            )
        }
    }
}

// MARK: - ButtonConfig

private extension YieldModuleBottomSheetNotificationBannerView {
    struct ButtonConfig {
        let title: String
        let action: () -> Void
        let style: MainButton.Style
    }
}
