//
//  TangemPayVirtualAccountBankDetailsView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization
import TangemAccessibilityIdentifiers

struct TangemPayVirtualAccountBankDetailsView: View {
    @ObservedObject var viewModel: TangemPayVirtualAccountBankDetailsViewModel

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 0) {
                    rows

                    banner
                        .padding(.top, 16)
                }
            }

            shareButton
                .padding(.top, 16)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = DesignSystem.Color.bgSecondary
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }

    private var header: some View {
        // [REDACTED_TODO_COMMENT]
        BottomSheetHeaderView(title: "Account details", trailing: { closeButton })
            .titleFont(DesignSystem.Font.bodyMediumToken.font)
            .titleColor(DesignSystem.Color.textPrimary)
    }

    private var closeButton: some View {
        TangemButtonV2(icon: DesignSystem.Icons.Cross.regular20, accessibilityLabel: Localization.commonClose, action: viewModel.close)
            .size(.x11)
            .styleType(.material(.glass))
    }

    private var rows: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.rows.enumerated()), id: \.element.id) { index, row in
                rowView(row)

                if index < viewModel.rows.count - 1 {
                    Divider()
                }
            }
        }
    }

    private func rowView(_ row: TangemPayVirtualAccountBankDetailsViewModel.Row) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: row.title)
                    .font(token: DesignSystem.Font.captionMediumToken)
                    .foregroundStyle(DesignSystem.Color.textSecondary)

                Text(verbatim: row.value)
                    .font(token: DesignSystem.Font.subheadingMediumToken)
                    .foregroundStyle(DesignSystem.Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.virtualAccountBankDetailValue(row.key))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: { viewModel.copy(row.value) }) {
                DesignSystem.Icons.Copy.regular24.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(DesignSystem.Color.iconSecondary)
            }
            .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.virtualAccountBankDetailCopyButton(row.key))
        }
        .padding(.vertical, 14)
    }

    private var banner: some View {
        HStack(alignment: .top, spacing: 8) {
            DesignSystem.Icons.Info.regular20.image
                .renderingMode(.template)
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundStyle(DesignSystem.Color.iconStatusInfo)

            VStack(alignment: .leading, spacing: 2) {
                // [REDACTED_TODO_COMMENT]
                Text("Available to deposit per day: $10,000")
                    .font(token: DesignSystem.Font.subheadingMediumToken)
                    .foregroundStyle(DesignSystem.Color.textPrimary)

                // [REDACTED_TODO_COMMENT]
                Text("Limit is resetting every day")
                    .font(token: DesignSystem.Font.captionMediumToken)
                    .foregroundStyle(DesignSystem.Color.textSecondary)
            }
            .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(DesignSystem.Color.bgStatusInfoSubtle, in: RoundedRectangle(cornerRadius: 14))
    }

    private var shareButton: some View {
        TangemButtonV2(
            label: AttributedString(Localization.commonShare),
            accessibilityLabel: Localization.commonShare,
            action: viewModel.share
        )
        .size(.x14)
        .horizontalLayout(.infinity)
        .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.virtualAccountBankDetailsShareButton)
    }
}
