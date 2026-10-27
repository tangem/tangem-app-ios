//
//  TangemPayVirtualAccountFeeListView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct TangemPayVirtualAccountFeeListView: View {
    let state: TangemPayVirtualAccountInfoSheetViewModel.State
    let reload: () -> Void

    var body: some View {
        switch state {
        case .loading:
            feeList {
                feePlaceholderRow

                divider

                feePlaceholderRow
            }
        case .loaded(let fees):
            feeList {
                ForEach(Array(fees.enumerated()), id: \.element.id) { index, fee in
                    feeRow(fee)

                    if index < fees.count - 1 {
                        divider
                    }
                }
            }
        case .empty:
            EmptyView()
        case .failed:
            feeErrorBanner
        }
    }

    private func feeList(@ViewBuilder rows: () -> some View) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text(Localization.tangempayBankTransferOnboardingFeeHeader)
                    .font(token: DesignSystem.Font.subheadingMediumToken)
                    .foregroundStyle(DesignSystem.Color.textSecondary)

                Spacer(minLength: 0)
            }
            .padding(.vertical, 8)

            rows()
        }
    }

    private var divider: some View {
        DesignSystem.Color.borderSecondary
            .frame(height: 1)
    }

    private var feeErrorBanner: some View {
        MessageBanner(
            title: Localization.tangempayBankTransferFeeErrorTitle,
            description: Localization.tangempayBankTransferFeeErrorSubtitle
        )
        .variant(.error)
        .slotEnd {
            DesignSystem.Icons.ArrowRefresh.regular20.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconPrimary)
        }
        .onTap(reload)
        .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.virtualAccountFeeErrorBanner)
    }

    private func feeRow(_ fee: TangemPayVirtualAccountFee) -> some View {
        HStack(spacing: 0) {
            Text(verbatim: fee.title)
                .font(token: DesignSystem.Font.bodyMediumToken)
                .foregroundStyle(DesignSystem.Color.textPrimary)
                .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.virtualAccountFeeTitle(fee.id))

            Spacer(minLength: 0)

            Text(verbatim: fee.value)
                .font(token: DesignSystem.Font.bodyMediumToken)
                .foregroundStyle(DesignSystem.Color.textSecondary)
                .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.virtualAccountFeeValue(fee.id))
        }
        .padding(.vertical, 12)
    }

    private var feePlaceholderRow: some View {
        HStack(spacing: 12) {
            Shimmer()
                .variant(.text(style: .body, alignment: .leading))

            Shimmer()
                .variant(.text(style: .body, alignment: .trailing))
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    VStack(spacing: 32) {
        TangemPayVirtualAccountFeeListView(
            state: .loading,
            reload: {}
        )

        TangemPayVirtualAccountFeeListView(
            state: .loaded(.previews),
            reload: {}
        )

        TangemPayVirtualAccountFeeListView(
            state: .empty,
            reload: {}
        )

        TangemPayVirtualAccountFeeListView(
            state: .failed,
            reload: {}
        )
    }
    .padding(24)
    .background(DesignSystem.Color.bgPrimary)
}
#endif
