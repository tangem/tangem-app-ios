//
//  TransactionDetailsDebugView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets
import TangemLocalization

struct TransactionDetailsDebugView: View {
    @ObservedObject var viewModel: TransactionDetailsDebugViewModel

    var body: some View {
        VStack(spacing: .zero) {
            header

            summarySection

            Separator(color: DesignSystem.Color.borderSecondary)

            ScrollView {
                Text(viewModel.dumpText)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(DesignSystem.Color.textPrimary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            }

            MainButton(
                title: Localization.commonCopy,
                icon: .leading(Assets.Glyphs.copy),
                action: viewModel.copyTapped
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("Debug view")
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)

            Spacer(minLength: 8)

            CircleButton(image: DesignSystem.Icons.Cross.regular20, action: viewModel.closeTapped)
                .size(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(viewModel.summary) { row in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(row.title)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                        .frame(width: 96, alignment: .leading)

                    Text(row.value)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
}

// MARK: - Previews

#Preview {
    TransactionDetailsDebugView(
        viewModel: TransactionDetailsDebugViewModel(
            info: TransactionDetailsDebugInfo(
                summary: [
                    .init(title: "Source", value: "BSDK + Express (merged)"),
                    .init(title: "Operation", value: "Swap"),
                    .init(title: "Synthetic", value: "No"),
                ],
                dump: """
                TransactionRecord(
                    hash = "0x4467d8d48b18fe57507f031557fac5268d4d",
                    index = 0,
                    status = confirmed,
                    isOutgoing = false,
                    type = transfer
                )
                """
            )
        )
    )
}

#endif
