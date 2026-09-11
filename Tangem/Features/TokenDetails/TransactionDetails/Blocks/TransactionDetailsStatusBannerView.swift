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
        /// Blue, spinning loader (e.g. "In progress", "Awaiting funds", "Deposit confirmed").
        case inProgress
        /// Yellow, spinning loader ("Refunding"). Stays.
        case refunding
        /// Green checkmark (e.g. "Funds received"). The caller auto-dismisses it after a delay.
        case success
        /// Red error glyph ("Failed"). Stays.
        case failed
        /// Red clock ("Expired"). Stays.
        case expired
        /// Red error glyph ("Refunded"). Stays.
        case refunded
        /// Yellow exclamation (e.g. "Verification required", "Paused"). Stays.
        case attention
        /// Red error — the "Refunded in [TOKEN]" plaque.
        case refundInfo
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
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(data.title)
                    .style(DesignSystem.Font.bodyMediumToken, color: titleColor)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: data.title)
                    .frame(maxWidth: .infinity, alignment: .leading)

                indicator
                    .frame(size: CGSize(bothDimensions: indicatorSide))
            }

            if let subtitle = data.subtitle {
                Text(subtitle)
                    .style(DesignSystem.Font.captionMediumToken, color: subtitleColor)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: subtitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 20))
        .animation(.easeInOut(duration: 0.3), value: data.kind)
    }

    @ViewBuilder
    private var indicator: some View {
        switch data.kind {
        case .inProgress:
            loader(color: DesignSystem.Color.iconStatusInfo)
        case .refunding:
            loader(color: DesignSystem.Color.iconStatusWarning)
        case .success:
            glyph(DesignSystem.Icons.Success.filled20, color: DesignSystem.Color.iconStatusSuccess)
        case .failed, .refunded, .refundInfo:
            glyph(DesignSystem.Icons.Error.filled20, color: DesignSystem.Color.iconStatusError)
        case .expired:
            glyph(DesignSystem.Icons.Clock.regular20, color: DesignSystem.Color.iconStatusError)
        case .attention:
            glyph(DesignSystem.Icons.Warning.filled20, color: DesignSystem.Color.iconStatusWarning)
        }
    }

    private func loader(color: Color) -> some View {
        Loader()
            .loaderSize(.size20)
            .loaderColor(color)
    }

    private func glyph(_ image: ImageType, color: Color) -> some View {
        image.image
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(color)
    }

    private var titleColor: Color {
        switch data.kind {
        case .inProgress: DesignSystem.Color.textStatusInfo
        case .success: DesignSystem.Color.textStatusSuccess
        case .failed, .expired, .refunded, .refundInfo: DesignSystem.Color.textStatusError
        case .refunding, .attention: DesignSystem.Color.textStatusWarning
        }
    }

    private var subtitleColor: Color {
        titleColor
    }

    private var backgroundColor: Color {
        switch data.kind {
        case .inProgress: DesignSystem.Color.bgStatusInfoSubtle
        case .success: DesignSystem.Color.bgStatusSuccessSubtle
        case .failed, .expired, .refunded, .refundInfo: DesignSystem.Color.bgStatusErrorSubtle
        case .refunding, .attention: DesignSystem.Color.bgStatusWarningSubtle
        }
    }
}

// MARK: - Previews

#Preview("Status banner") {
    StatusBannerDemoView()
}

#Preview("Status states") {
    VStack(spacing: 12) {
        TransactionDetailsStatusBannerView(data: .init(kind: .inProgress, title: "In progress"))
        TransactionDetailsStatusBannerView(data: .init(kind: .refunding, title: "Refunding"))
        TransactionDetailsStatusBannerView(data: .init(kind: .success, title: "Funds received"))
        TransactionDetailsStatusBannerView(data: .init(kind: .failed, title: "Failed", subtitle: "Visit provider's website to refund your money"))
        TransactionDetailsStatusBannerView(data: .init(kind: .expired, title: "Expired"))
        TransactionDetailsStatusBannerView(data: .init(kind: .refunded, title: "Refunded"))
        TransactionDetailsStatusBannerView(data: .init(
            kind: .refundInfo,
            title: "Refunded in WBTC",
            subtitle: "Your funds have been refunded in WBTC to your wallet on the Polygon network, in accordance with OKX exchange rules."
        ))
        TransactionDetailsStatusBannerView(data: .init(kind: .attention, title: "Verification required", subtitle: "Visit provider's website to refund your money"))
    }
    .padding(16)
    .background(DesignSystem.Color.bgPrimary)
}
