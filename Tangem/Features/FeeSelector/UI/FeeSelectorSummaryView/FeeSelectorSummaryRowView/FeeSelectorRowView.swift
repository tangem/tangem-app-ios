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
        if viewModel.selectAction != nil {
            Button(action: onSelectAction) {
                content
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }

    // MARK: - Sub Views

    private var content: some View {
        HStack(alignment: .center, spacing: 12) {
            icon
            labels
            Spacer()
            expandButton
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 14)
        .accessibilityIdentifier(viewModel.accessibilityIdentifier)
        .background(backgroundView)
        .overlay { SelectionOverlay().opacity(viewModel.isSelected ? 1 : 0) }
    }

    private var labels: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.title)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                .multilineTextAlignment(.leading)

            LoadableTextView(
                state: viewModel.subtitle,
                font: Fonts.Regular.caption1,
                textColor: Colors.Text.tertiary,
                loaderSize: CGSize(width: 100, height: 16),
                isSensitiveText: viewModel.rowType.isToken
            )
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
            .fill(Colors.Background.action)
    }

    @ViewBuilder
    private var expandButton: some View {
        if let action = viewModel.expandAction {
            Button(action: action) {
                Assets.Glyphs.selectIcon.image
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(Colors.Text.tertiary)
                    .frame(width: 18, height: 24)
            }
        }
    }

    private var feeIconBackgroundColor: Color {
        if viewModel.selectAction != nil {
            return viewModel.isSelected ? Colors.Icon.accent.opacity(0.1) : Colors.Background.tertiary
        }

        return Colors.Icon.accent.opacity(0.1)
    }

    private var feeIconColor: Color {
        if viewModel.selectAction != nil {
            return viewModel.isSelected ? Colors.Icon.accent : Colors.Text.tertiary
        }

        return Colors.Icon.accent
    }

    // MARK: - Private Implementation

    private func onSelectAction() {
        if !viewModel.isSelected {
            FeedbackGenerator.selectionChanged()
        }

        viewModel.selectAction?()
    }
}

#Preview("Summary Row Variants") {
    ZStack {
        Colors.Background.tertiary.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 16) {
                FeeSelectorRowView(
                    viewModel: FeeSelectorRowViewModel(
                        rowType: .fee(image: Assets.FeeOptions.marketFeeIcon.image),
                        title: "Network Fee",
                        subtitle: .loaded(text: "~ 0.0012 ETH ($3.45)"),
                        accessibilityIdentifier: "fee_selector_summary_fee",
                        expandAction: {}
                    )
                )

                FeeSelectorRowView(
                    viewModel: FeeSelectorRowViewModel(
                        rowType: .fee(image: Assets.FeeOptions.marketFeeIcon.image),
                        title: "Tether",
                        subtitle: .loaded(text: "Balance: $573.07"),
                        accessibilityIdentifier: "fee_selector_summary_token",
                        expandAction: nil
                    )
                )

                FeeSelectorRowView(
                    viewModel: FeeSelectorRowViewModel(
                        rowType: .fee(image: Assets.FeeOptions.marketFeeIcon.image),
                        title: "Tether",
                        subtitle: .loading,
                        accessibilityIdentifier: "fee_selector_summary_token",
                        expandAction: nil
                    )
                )

                FeeSelectorRowView(
                    viewModel: FeeSelectorRowViewModel(
                        rowType: .token(tokenIconInfo: TokenIconInfoBuilder().build(from: "ETH")),
                        title: "Tether",
                        subtitle: .noData,
                        accessibilityIdentifier: "fee_selector_summary_token",
                        expandAction: nil
                    )
                )

                FeeSelectorRowView(
                    viewModel: FeeSelectorRowViewModel(
                        rowType: .token(tokenIconInfo: TokenIconInfoBuilder().build(from: "ETH")),
                        title: "Tether",
                        subtitle: .noData,
                        accessibilityIdentifier: "fee_selector_summary_token",
                        isSelected: true,
                        selectAction: {}
                    )
                )

                FeeSelectorRowView(
                    viewModel: FeeSelectorRowViewModel(
                        rowType: .fee(image: Assets.FeeOptions.marketFeeIcon.image),
                        title: "Tether",
                        subtitle: .noData,
                        accessibilityIdentifier: "fee_selector_summary_token",
                        isSelected: true,
                        selectAction: {}
                    )
                )

                FeeSelectorRowView(
                    viewModel: FeeSelectorRowViewModel(
                        rowType: .fee(image: Assets.FeeOptions.marketFeeIcon.image),
                        title: "Tether",
                        subtitle: .noData,
                        accessibilityIdentifier: "fee_selector_summary_token",
                        isSelected: false,
                        selectAction: {}
                    )
                )

                FeeSelectorRowView(
                    viewModel: FeeSelectorRowViewModel(
                        rowType: .fee(image: Assets.FeeOptions.marketFeeIcon.image),
                        title: "Tether",
                        subtitle: .noData,
                        accessibilityIdentifier: "fee_selector_summary_token"
                    )
                )
            }
            .padding(.horizontal, 24)
            .background(Colors.Background.tertiary)
        }
    }
}

extension FeeSelectorRowView {
    enum Constants {
        static let defaultIconSize: CGSize = .init(width: 36, height: 36)
        static let feeIconSize: CGSize = .init(width: 24, height: 24)
    }
}
