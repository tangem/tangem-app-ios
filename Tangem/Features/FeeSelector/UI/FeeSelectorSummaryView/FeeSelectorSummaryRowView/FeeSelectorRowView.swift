//
//  FeeSelectorSummaryRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import enum TangemFoundation.FeedbackGenerator

struct FeeSelectorRowView: View {
    // MARK: - Model

    let viewModel: FeeSelectorRowViewModel

    // MARK: - View Body

    var body: some View {
        SwiftUI.Button(action: action) {
            content
        }
        .buttonStyle(.plain)
        .disabled(viewModel.availability.isUnavailable)
        .accessibilityIdentifier(viewModel.accessibilityIdentifier)
    }

    // MARK: - Sub Views

    private var content: some View {
        HStack(alignment: .center, spacing: 12) {
            icon
            labels
            Spacer()
            expandIcon
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 14)
        .background(backgroundView)
        .overlay { SelectionOverlay().opacity(viewModel.isSelected ? 1 : 0) }
    }

    private var labels: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.title)
                .lineLimit(1)
                .style(Fonts.Bold.subheadline, color: DesignSystem.Color.textPrimary)
                .multilineTextAlignment(.leading)

            switch viewModel.subtitle {
            case .balance(let state):
                LoadableBalanceView(
                    state: state,
                    style: .init(font: Fonts.Regular.caption1, textColor: DesignSystem.Color.textSecondary),
                    loader: .init(size: CGSize(width: 100, height: 14))
                )
            case .fee(let state):
                LoadableTextView(
                    state: state,
                    font: Fonts.Regular.caption1,
                    textColor: feeSubtitleColor(),
                    loaderSize: CGSize(width: 100, height: 14),
                    isSensitiveText: viewModel.rowType.isToken
                )
                .accessibilityIdentifier(viewModel.subtitleAccessibilityIdentifier)
            }
        }
    }

    private func feeSubtitleColor() -> Color {
        switch viewModel.availability {
        case .available(true), .unavailable(true):
            return DesignSystem.Color.textAccentRed
        case .available(false), .unavailable(false):
            return DesignSystem.Color.textSecondary
        }
    }

    @ViewBuilder
    private var icon: some View {
        switch viewModel.rowType {
        case .fee(let image):
            feeIcon(image: image)
        case .token(let tokenIconInfo):
            tokenIcon(tokenIconInfo: tokenIconInfo)
        }
    }

    private func feeIcon(image: Image) -> some View {
        ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: 18)
                .fill(feeIconBackgroundColor)
                .frame(size: Constants.defaultIconSize)

            image
                .resizable()
                .renderingMode(.template)
                .frame(size: Constants.feeIconSize)
                .foregroundStyle(feeIconColor)
        }
    }

    private func tokenIcon(tokenIconInfo: TokenIconInfo) -> some View {
        TokenIcon(tokenIconInfo: tokenIconInfo, size: Constants.defaultIconSize)
    }

    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(DesignSystem.Color.bgSecondary)
    }

    @ViewBuilder
    private var expandIcon: some View {
        if viewModel.expandAction != nil {
            Assets.Glyphs.selectIcon.image
                .renderingMode(.template)
                .resizable()
                .foregroundStyle(DesignSystem.Color.iconSecondary)
                .frame(width: 18, height: 24)
        }
    }

    private var feeIconBackgroundColor: Color {
        if viewModel.selectAction != nil {
            return viewModel.isSelected ? DesignSystem.Color.bgAccentBlueSubtle : DesignSystem.Color.bgTransparentPrimary
        }

        return DesignSystem.Color.bgAccentBlueSubtle
    }

    private var feeIconColor: Color {
        if viewModel.selectAction != nil {
            return viewModel.isSelected ? DesignSystem.Color.iconAccentBlue : DesignSystem.Color.iconSecondary
        }

        return DesignSystem.Color.iconAccentBlue
    }

    // MARK: - Private Implementation

    private func action() {
        if let selectAction = viewModel.selectAction {
            if !viewModel.isSelected {
                FeedbackGenerator.selectionChanged()
            }
            selectAction()
            return
        }

        viewModel.expandAction?()
    }
}

#Preview("Summary Row Variants") {
    ZStack {
        DesignSystem.Color.bgPrimary.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 16) {
                FeeSelectorRowView(
                    viewModel: FeeSelectorRowViewModel(
                        rowType: .fee(image: Assets.FeeOptions.marketFeeIcon.image),
                        title: "Network Fee",
                        subtitle: .fee(.loaded(text: "~ 0.0012 ETH ($3.45)")),
                        accessibilityIdentifier: "fee_selector_summary_fee",
                        expandAction: {}
                    )
                )

                FeeSelectorRowView(
                    viewModel: FeeSelectorRowViewModel(
                        rowType: .fee(image: Assets.FeeOptions.marketFeeIcon.image),
                        title: "Tether",
                        subtitle: .balance(.loaded(text: "Balance: $573.07")),
                        accessibilityIdentifier: "fee_selector_summary_token",
                        expandAction: nil
                    )
                )

                FeeSelectorRowView(
                    viewModel: FeeSelectorRowViewModel(
                        rowType: .fee(image: Assets.FeeOptions.marketFeeIcon.image),
                        title: "Tether",
                        subtitle: .fee(.loading),
                        accessibilityIdentifier: "fee_selector_summary_token",
                        expandAction: nil
                    )
                )

                FeeSelectorRowView(
                    viewModel: FeeSelectorRowViewModel(
                        rowType: .token(tokenIconInfo: TokenIconInfoBuilder().build(from: "ETH")),
                        title: "Tether",
                        subtitle: .fee(.noData),
                        accessibilityIdentifier: "fee_selector_summary_token",
                        expandAction: nil
                    )
                )

                FeeSelectorRowView(
                    viewModel: FeeSelectorRowViewModel(
                        rowType: .token(tokenIconInfo: TokenIconInfoBuilder().build(from: "ETH")),
                        title: "Tether",
                        subtitle: .fee(.noData),
                        accessibilityIdentifier: "fee_selector_summary_token",
                        isSelected: true,
                        selectAction: {}
                    )
                )

                FeeSelectorRowView(
                    viewModel: FeeSelectorRowViewModel(
                        rowType: .fee(image: Assets.FeeOptions.marketFeeIcon.image),
                        title: "Tether",
                        subtitle: .fee(.noData),
                        accessibilityIdentifier: "fee_selector_summary_token",
                        isSelected: true,
                        selectAction: {}
                    )
                )

                FeeSelectorRowView(
                    viewModel: FeeSelectorRowViewModel(
                        rowType: .fee(image: Assets.FeeOptions.marketFeeIcon.image),
                        title: "Tether",
                        subtitle: .fee(.noData),
                        accessibilityIdentifier: "fee_selector_summary_token",
                        isSelected: false,
                        selectAction: {}
                    )
                )

                FeeSelectorRowView(
                    viewModel: FeeSelectorRowViewModel(
                        rowType: .fee(image: Assets.FeeOptions.marketFeeIcon.image),
                        title: "Tether",
                        subtitle: .fee(.noData),
                        accessibilityIdentifier: "fee_selector_summary_token"
                    )
                )
            }
            .padding(.horizontal, 24)
            .background(DesignSystem.Color.bgPrimary)
        }
    }
}

extension FeeSelectorRowView {
    enum Constants {
        static let defaultIconSize: CGSize = .init(width: 36, height: 36)
        static let feeIconSize: CGSize = .init(width: 24, height: 24)
    }
}
