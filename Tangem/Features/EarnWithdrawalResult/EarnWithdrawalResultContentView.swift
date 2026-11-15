//
//  EarnWithdrawalResultContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct EarnWithdrawalResultContentView: View {
    let state: StateModel
    let action: (Action) -> Void

    var body: some View {
        StatusScreen(
            title: state.title,
            description: state.summary,
            actionTitle: Localization.commonDone,
            action: { action(.done) }
        )
        .appearance(state.status.appearance)
        .assetSlot {
            StatusIcon(.checkmark)
                .tint(state.status.iconTint)
                .startDelay(Constants.iconStartDelay)
        }
        .details { details }
        .footerHidden()
        .footer {
            Footer(
                .toolbar(
                    start: ButtonStack(exploreButton, shareButton),
                    end: doneButton
                )
            )
        }
    }
}

// MARK: - Details

private extension EarnWithdrawalResultContentView {
    var details: some View {
        VStack(spacing: 0) {
            // [REDACTED_TODO_COMMENT]
            Row(title: "Withdrawal period", value: state.withdrawalPeriod)
                .overrideTextColors(RowOverrideTextColors(value: DesignSystem.Color.textSecondary))
                .showDivider()

            Row(title: Localization.commonNetworkFeeTitle)
                .end {
                    HStack(spacing: Constants.feeSpacing) {
                        if let symbol = state.fee.symbol {
                            Badge(label: symbol, accessibilityLabel: nil)
                        }

                        Text(state.fee.value)
                            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
                    }
                }
        }
    }
}

// MARK: - Bottom bar

private extension EarnWithdrawalResultContentView {
    var exploreButton: TangemUI.Button {
        TangemUI.Button(
            icon: DesignSystem.Icons.Globe.regular20,
            accessibilityLabel: Localization.commonExplore,
            action: { action(.explore) }
        )
        .enabled(state.hasTransactionLink)
    }

    var shareButton: TangemUI.Button {
        TangemUI.Button(
            icon: DesignSystem.Icons.ShareIos.regular20,
            accessibilityLabel: Localization.commonShare,
            action: { action(.share) }
        )
        .enabled(state.hasTransactionLink)
    }

    var doneButton: TangemUI.Button {
        TangemUI.Button(
            icon: DesignSystem.Icons.Checkmark.regular20,
            accessibilityLabel: Localization.commonDone,
            action: { action(.done) }
        )
        .styleType(.primary)
        .size(.x11)
    }
}

// MARK: - StateModel

extension EarnWithdrawalResultContentView {
    struct StateModel: Equatable {
        let status: Status
        let title: String
        let summary: String
        let withdrawalPeriod: String
        let fee: Fee
        let hasTransactionLink: Bool
    }

    enum Status: Equatable {
        case withdrawn
        case inProgress
    }

    struct Fee: Equatable {
        let symbol: String?
        let value: String
    }

    enum Action: Equatable {
        case explore
        case share
        case done
    }
}

private extension EarnWithdrawalResultContentView.Status {
    var appearance: StatusScreenAppearance {
        switch self {
        case .withdrawn: .success
        case .inProgress: .info
        }
    }

    var iconTint: Color {
        switch self {
        case .withdrawn: DesignSystem.Color.iconStatusSuccess
        case .inProgress: DesignSystem.Color.iconStatusInfo
        }
    }
}

// MARK: - Constants

private extension EarnWithdrawalResultContentView {
    enum Constants {
        static let iconStartDelay: TimeInterval = 0.3
        static let feeSpacing: CGFloat = 8
    }
}

// MARK: - Previews

#Preview("Withdrawn") {
    EarnWithdrawalResultContentView(state: .preview(status: .withdrawn, withdrawalPeriod: "Up to 48 hours"), action: { _ in })
}

#Preview("In progress") {
    EarnWithdrawalResultContentView(state: .preview(status: .inProgress, withdrawalPeriod: "Up to 48 hours"), action: { _ in })
}
