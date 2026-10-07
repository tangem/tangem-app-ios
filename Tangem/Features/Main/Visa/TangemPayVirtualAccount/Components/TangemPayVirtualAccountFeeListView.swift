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
    let header: String
    let state: TangemPayVirtualAccountInfoSheetViewModel.State
    let rowsHorizontalPadding: CGFloat
    let reload: () -> Void

    var body: some View {
        switch state {
        case .loading:
            feeList(achFee: nil, fedwireFee: nil, isLoading: true)
        case .loaded(let achFee, let fedwireFee):
            feeList(achFee: achFee, fedwireFee: fedwireFee, isLoading: false)
        case .failed:
            feeErrorBanner
        }
    }

    private func feeList(achFee: String?, fedwireFee: String?, isLoading: Bool) -> some View {
        let showsAch = isLoading || achFee != nil
        let showsFedwire = isLoading || fedwireFee != nil

        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text(header)
                    .font(token: DesignSystem.Font.subheadingMediumToken)
                    .foregroundStyle(DesignSystem.Color.textSecondary)

                Spacer(minLength: 0)
            }
            .padding(.vertical, 8)

            if showsAch {
                feeRow(title: Localization.tangempayBankTransferFeeAch, value: achFee, fee: .ach)
            }

            if showsAch, showsFedwire {
                DesignSystem.Color.borderSecondary
                    .frame(height: 1)
            }

            if showsFedwire {
                feeRow(title: Localization.tangempayBankTransferFeeFedwire, value: fedwireFee, fee: .fedwire)
            }
        }
        .padding(.horizontal, rowsHorizontalPadding)
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

    private func feeRow(title: String, value: String?, fee: TangemPayAccessibilityIdentifiers.VirtualAccountFee) -> some View {
        HStack(spacing: 0) {
            Text(verbatim: title)
                .font(token: DesignSystem.Font.bodyMediumToken)
                .foregroundStyle(DesignSystem.Color.textPrimary)
                .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.virtualAccountFeeTitle(fee))

            Spacer(minLength: 0)

            if let value {
                Text(verbatim: value)
                    .font(token: DesignSystem.Font.bodyMediumToken)
                    .foregroundStyle(DesignSystem.Color.textSecondary)
                    .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.virtualAccountFeeValue(fee))
            }
        }
        .overlay(alignment: .trailing) {
            if value == nil {
                Shimmer()
                    .variant(.text(style: .body, alignment: .trailing))
            }
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 32) {
        TangemPayVirtualAccountFeeListView(
            header: Localization.tangempayBankTransferOnboardingFeeHeader,
            state: .loading,
            rowsHorizontalPadding: 0,
            reload: {}
        )

        TangemPayVirtualAccountFeeListView(
            header: Localization.tangempayBankTransferOnboardingFeeHeader,
            state: .loaded(achFee: "$0", fedwireFee: "$0"),
            rowsHorizontalPadding: 0,
            reload: {}
        )

        TangemPayVirtualAccountFeeListView(
            header: Localization.tangempayBankTransferOnboardingFeeHeader,
            state: .failed,
            rowsHorizontalPadding: 0,
            reload: {}
        )
    }
    .padding(24)
    .background(DesignSystem.Color.bgPrimary)
}
