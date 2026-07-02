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
            indicator
                .frame(size: CGSize(bothDimensions: indicatorSide))

            VStack(alignment: .leading, spacing: 2) {
                Text(data.title)
                    .style(DesignSystem.Font.bodyMediumToken, color: titleColor)

                if let subtitle = data.subtitle {
                    Text(subtitle)
                        .style(DesignSystem.Font.captionMediumToken, color: subtitleColor)
                }
            }

            Spacer(minLength: .zero)
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

@available(iOS 17.0, *)
#Preview("Status banner") {
    @Previewable @State var status: TransactionDetailsStatusBannerViewData?

    func set(_ value: TransactionDetailsStatusBannerViewData?) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { status = value }
    }

    func showSuccess() {
        set(.init(kind: .success, title: "Funds received"))
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            set(nil)
        }
    }

    func playFlow() {
        Task { @MainActor in
            set(.init(kind: .inProgress, title: "Awaiting funds"))
            try? await Task.sleep(for: .seconds(1.5))
            set(.init(kind: .inProgress, title: "Deposit confirmed"))
            try? await Task.sleep(for: .seconds(1.5))
            showSuccess()
        }
    }

    return VStack(spacing: 16) {
        RoundedRectangle(cornerRadius: 24)
            .fill(DesignSystem.Color.bgTertiary)
            .frame(height: 120)
            .overlay { Text("Token / pair card").style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textTertiary) }

        if let status {
            TransactionDetailsStatusBannerView(data: status)
                .transition(.move(edge: .top).combined(with: .opacity))
        }

        VStack(spacing: 8) {
            Button("▶︎ Play swap flow", action: playFlow)
            Button("In progress") { set(.init(kind: .inProgress, title: "Awaiting funds")) }
            Button("Success (auto-hide)") { showSuccess() }
            Button("Failed") { set(.init(kind: .warning, title: "Failed", subtitle: "Visit provider's website to refund your money")) }
            Button("Verification required") { set(.init(kind: .attention, title: "Verification required", subtitle: "Visit provider's website to refund your money")) }
            Button("Hide") { set(nil) }
        }
        .buttonStyle(.bordered)
        .padding(.top, 16)
    }
    .padding(16)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
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
