//
//  YieldModuleBottomSheetNotificationBanner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct YieldModuleBottomSheetNotificationBanner: View {
    // MARK: - Config

    let params: YieldModuleViewConfigs.YieldModuleNotificationBannerParams

    // MARK: - Properties

    private var title: String {
        switch params {
        case .approveNeeded:
            return Localization.yieldModuleApproveNeededNotificationTitle
        case .notEnoughFeeCurrency(let feeCurrencyName, _, _):
            return Localization.yieldModuleUnableToCoverFeeTitle(feeCurrencyName)
        }
    }

    private var description: String {
        switch params {
        case .approveNeeded:
            return Localization.yieldModuleApproveNeededNotificationDescription
        case .notEnoughFeeCurrency(let feeCurrencyName, _, _):
            return Localization.yieldModuleUnableToCoverFeeDescription(feeCurrencyName, "")
        }
    }

    private var buttonTitleText: String {
        switch params {
        case .approveNeeded:
            Localization.yieldModuleApproveNeededNotificationCta
        case .notEnoughFeeCurrency(let feeCurrencyName, _, _):
            Localization.commonBuyCurrency(feeCurrencyName)
        }
    }

    private var buttonAction: () -> Void {
        switch params {
        case .approveNeeded(let action):
            return action
        case .notEnoughFeeCurrency(_, _, let action):
            return action
        }
    }

    private var topPadding: CGFloat {
        switch params {
        case .approveNeeded:
            return 8
        case .notEnoughFeeCurrency:
            return 26
        }
    }

    private var buttonStyleColor: MainButton.Style {
        switch params {
        case .approveNeeded:
            return .primary
        case .notEnoughFeeCurrency:
            return .secondary
        }
    }

    // MARK: - View Body

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                iconStack
                message
                Spacer()
            }

            button
        }
        .defaultRoundedBackground()
        .padding(.top, topPadding)
    }

    // MARK: - Sub Views

    private var iconStack: some View {
        VStack {
            icon
                .resizable()
                .frame(size: .init(bothDimensions: 16))
            Spacer()
        }
    }

    private var message: some View {
        VStack(alignment: .leading, spacing: 2) {
            titleView
            descriptionView
        }
    }

    private var icon: Image {
        switch params {
        case .approveNeeded:
            return Assets.attention.image
        case .notEnoughFeeCurrency(_, let tokenIcon, _):
            return tokenIcon.image
        }
    }

    private var titleView: some View {
        Text(title)
            .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
    }

    private var descriptionView: some View {
        Text(description)
            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
    }

    private var button: some View {
        MainButton(title: buttonTitleText, style: buttonStyleColor, size: .notification, action: buttonAction)
    }
}
