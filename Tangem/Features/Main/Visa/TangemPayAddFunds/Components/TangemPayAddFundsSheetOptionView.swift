//
//  TangemPayAddFundsSheetOptionView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemAccessibilityIdentifiers
import TangemLocalization
import TangemMacro

struct TangemPayAddFundsSheetOptionView: View {
    let option: Option
    let action: () -> Void

    var body: some View {
        content
    }
}

private extension TangemPayAddFundsSheetOptionView {
    var content: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                icon

                titleView
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
        }
        .disabled(option.isPending)
        .accessibilityIdentifier(option.accessibilityIdentifier)
    }

    var icon: some View {
        option.icon.image
            .renderingMode(.template)
            .resizable()
            .frame(width: 20, height: 20)
            .foregroundStyle(
                option.isPending
                    ? DesignSystem.Color.iconStatusWarning
                    : DesignSystem.Color.iconBrand
            )
            .frame(width: 40, height: 40)
            .background(
                option.isPending
                    ? DesignSystem.Color.bgStatusWarningSubtle
                    : DesignSystem.Color.bgStatusInfoSubtle,
                in: Circle()
            )
    }

    var titleView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(option.title)
                .font(token: DesignSystem.Font.subheadingMediumToken)
                .foregroundStyle(DesignSystem.Color.textPrimary)

            Text(option.subtitle)
                .font(token: DesignSystem.Font.captionMediumToken)
                .foregroundStyle(DesignSystem.Color.textSecondary)
        }
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension TangemPayAddFundsSheetOptionView {
    @RawCaseName
    enum Option: Identifiable {
        case receive
        case swap
        case bankTransfer(pending: Bool)

        var title: String {
            switch self {
            case .receive: Localization.tangempayTopupReceiveTitle
            case .swap: Localization.tangempayTopupSwapTitle
            case .bankTransfer: Localization.tangempayTopupBankTransferTitle
            }
        }

        var subtitle: String {
            switch self {
            case .receive: Localization.tangempayTopupReceiveBodyMultichain
            case .swap: Localization.tangempayTopupSwapBody
            case .bankTransfer(let pending):
                pending ? Localization.tangempayTopupBankTransferPendingBody : Localization.tangempayTopupBankTransferBody
            }
        }

        var icon: ImageType {
            switch self {
            case .receive:
                DesignSystem.Icons.Grid.regular20
            case .swap:
                DesignSystem.Icons.ArrowSwapHorizontal.regular20
            case .bankTransfer(let pending):
                pending ? DesignSystem.Icons.Clock.regular20 : DesignSystem.Icons.Government.regular20
            }
        }

        var isPending: Bool {
            switch self {
            case .bankTransfer(let pending):
                return pending
            default:
                return false
            }
        }

        var accessibilityIdentifier: String {
            switch self {
            case .receive: TangemPayAccessibilityIdentifiers.addFundsSheetReceiveOption
            case .swap: TangemPayAccessibilityIdentifiers.addFundsSheetSwapOption
            case .bankTransfer: TangemPayAccessibilityIdentifiers.addFundsSheetBankTransferOption
            }
        }
    }
}

#Preview {
    VStack {
        TangemPayAddFundsSheetOptionView(
            option: .bankTransfer(pending: false),
            action: {}
        )

        TangemPayAddFundsSheetOptionView(
            option: .bankTransfer(pending: true),
            action: {}
        )
    }
    .padding(16)
}
