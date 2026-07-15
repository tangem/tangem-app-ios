//
//  TransactionDetailsStatusBannerView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct TransactionDetailsStatusBannerViewData: Equatable {
    enum Kind: Equatable {
        /// Blue, spinning loader (e.g. "Awaiting funds", "Deposit confirmed").
        case inProgress
        /// Green checkmark (e.g. "Funds received"). The caller auto-dismisses it after a delay.
        case success
        /// Red cross (e.g. "Failed"). Stays.
        case warning
        /// Yellow exclamation (e.g. "Verification required"). Stays.
        case attention
    }

    let kind: Kind
    let title: String
    let subtitle: String?

    init(kind: Kind, title: String, subtitle: String? = nil) {
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
    }
}

struct TransactionDetailsStatusBannerView: View {
    let data: TransactionDetailsStatusBannerViewData

    @ScaledMetric private var indicatorSide: CGFloat = 20

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(data.title)
                    .style(DesignSystem.Font.bodyMediumToken, color: titleColor)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: data.title)

                if let subtitle = data.subtitle {
                    Text(subtitle)
                        .style(DesignSystem.Font.captionMediumToken, color: subtitleColor)
                        .contentTransition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: subtitle)
                }
            }

            Spacer(minLength: .zero)

            indicator
                .frame(size: CGSize(bothDimensions: indicatorSide))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 24))
        .animation(.easeInOut(duration: 0.3), value: data.kind)
    }

    @ViewBuilder
    private var indicator: some View {
        switch data.kind {
        case .inProgress:
            TangemLoader()
                .loaderSize(.size20)
                .loaderColor(DesignSystem.Color.iconStatusInfo)
        case .success:
            badge(color: DesignSystem.Color.iconStatusSuccess, glyph: DesignSystem.Icons.Checkmark.regular20)
        case .warning:
            badge(color: DesignSystem.Color.iconStatusError, glyph: DesignSystem.Icons.Cross.regular20)
        case .attention:
            // [REDACTED_TODO_COMMENT]
            badge(color: DesignSystem.Color.iconStatusWarning, glyph: Assets.attention)
        }
    }

    private func badge(color: Color, glyph: ImageType) -> some View {
        Circle()
            .fill(color)
            .overlay {
                glyph.image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(size: CGSize(bothDimensions: indicatorSide * 0.6))
                    .foregroundStyle(DesignSystem.Color.iconStaticLight)
            }
    }

    private var titleColor: Color {
        switch data.kind {
        case .inProgress: DesignSystem.Color.textStatusInfo
        case .success: DesignSystem.Color.textStatusSuccess
        case .warning: DesignSystem.Color.textStatusError
        case .attention: DesignSystem.Color.textStatusWarning
        }
    }

    private var subtitleColor: Color {
        titleColor.opacity(0.7)
    }

    private var backgroundColor: Color {
        switch data.kind {
        case .inProgress: DesignSystem.Color.bgStatusInfoSubtle
        case .success: DesignSystem.Color.bgStatusSuccessSubtle
        case .warning: DesignSystem.Color.bgStatusErrorSubtle
        case .attention: DesignSystem.Color.bgStatusWarningSubtle
        }
    }
}

// MARK: - Previews

#Preview("Status banner") {
    StatusBannerDemoView()
}

#Preview("Status states") {
    VStack(spacing: 12) {
        TransactionDetailsStatusBannerView(data: .init(kind: .inProgress, title: "Awaiting funds"))
        TransactionDetailsStatusBannerView(data: .init(kind: .success, title: "Funds received"))
        TransactionDetailsStatusBannerView(data: .init(kind: .warning, title: "Failed", subtitle: "Visit provider's website to refund your money"))
        TransactionDetailsStatusBannerView(data: .init(kind: .attention, title: "Verification required", subtitle: "Visit provider's website to refund your money"))
    }
    .padding(16)
    .background(DesignSystem.Color.bgPrimary)
}
