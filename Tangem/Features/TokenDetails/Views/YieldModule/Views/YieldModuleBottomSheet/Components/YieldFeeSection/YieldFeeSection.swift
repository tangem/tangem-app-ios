//
//  YieldFeeSection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization
import TangemUIUtils
import TangemFoundation

struct YieldFeeSection<LeadingTextAccessoryView: View>: View {
    let leadingTitle: String
    let linkTitle: String?
    let url: URL?
    let needsBackground: Bool
    let onLinkTapAction: (() -> Void)?
    let notification: YieldModuleNotificationBannerParams?
    let feeSelector: YieldFeeSectionFeeSelector?
    let leadingTextAccessoryView: LeadingTextAccessoryView

    let sectionState: YieldFeeSectionState

    init(
        sectionState: YieldFeeSectionState,
        leadingTitle: String,
        needsBackground: Bool = true,
        linkTitle: String? = nil,
        url: URL? = nil,
        onLinkTapAction: (() -> Void)? = nil,
        notification: YieldModuleNotificationBannerParams? = nil,
        feeSelector: YieldFeeSectionFeeSelector? = nil,
        @ViewBuilder leadingTextAccessoryView: () -> LeadingTextAccessoryView = { EmptyView() }
    ) {
        self.leadingTitle = leadingTitle
        self.sectionState = sectionState
        self.needsBackground = needsBackground
        self.linkTitle = linkTitle
        self.url = url
        self.onLinkTapAction = onLinkTapAction
        self.notification = notification
        self.feeSelector = feeSelector
        self.leadingTextAccessoryView = leadingTextAccessoryView()
    }

    var body: some View {
        VStack(spacing: 14) {
            feeSection
            notificationView
        }
    }

    @ViewBuilder
    private var notificationView: some View {
        if let notification {
            YieldModuleBottomSheetNotificationBannerView(params: notification)
        }
    }

    private var feeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            feeRow

            if let footerText = sectionState.footerText {
                FooterText(
                    footerText: footerText,
                    linkTitle: linkTitle,
                    url: url,
                    isLinkActive: sectionState.isLinkActive,
                    onLinkTapAction: onLinkTapAction
                )
                .padding(.horizontal, 14)
            }
        }
    }

    @ViewBuilder
    private var feeRow: some View {
        if let feeSelector {
            FeeSelectorRow(viewModel: feeSelector.viewModel, tapAction: feeSelector.tapAction)
                .defaultRoundedBackground(with: DesignSystem.Color.bgSecondary, verticalPadding: 0, horizontalPadding: 0)
        } else {
            LoadableFeeRowView(
                leadingTitle: leadingTitle,
                state: sectionState.feeState,
                isHighlighted: sectionState.isHighlighted,
                leadingTextAccessoryView: leadingTextAccessoryView
            )
            .padding(.horizontal, 4)
            .if(needsBackground) { view in
                view.defaultRoundedBackground(
                    with: DesignSystem.Color.bgSecondary,
                    verticalPadding: 14
                )
            }
        }
    }
}

// MARK: - YieldFeeSectionFeeSelector

struct YieldFeeSectionFeeSelector {
    let viewModel: FeeCompactViewModel
    let tapAction: () -> Void
}

// MARK: - FeeSelectorRow

extension YieldFeeSection {
    struct FeeSelectorRow: View {
        @ObservedObject var viewModel: FeeCompactViewModel
        let tapAction: () -> Void

        var body: some View {
            Row(title: Localization.commonNetworkFeeTitle)
                .valueAccessory { feeValue }
                .end { editIcon }
                .onTap(action: viewModel.canEditFee ? tapAction : nil)
        }

        private var feeValue: some View {
            HStack(spacing: 4) {
                if let currencySymbol = viewModel.selectedFeeTokenCurrencySymbol {
                    Badge(label: currencySymbol, accessibilityLabel: nil)
                        .size(.x4)
                }

                feeAmount
            }
        }

        @ViewBuilder
        private var feeAmount: some View {
            switch viewModel.selectedFeeComponents {
            case .initialized, .loading:
                Shimmer()
                    .variant(.custom(width: 60, height: 20))
            case .noData:
                amountText(String.enDashSign)
            case .loadingCached(let text):
                amountText(text)
                    .shimmering(true)
            case .loaded(let text):
                amountText(text)
            }
        }

        private func amountText(_ text: String) -> some View {
            Text(text)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
                .lineLimit(1)
        }

        @ViewBuilder
        private var editIcon: some View {
            if viewModel.canEditFee {
                DesignSystem.Icons.ChevronDoubleVertical.regular20.image
                    .renderingMode(.template)
                    .foregroundStyle(DesignSystem.Color.iconSecondary)
                    .accessibilityHidden(true)
            }
        }
    }
}

// MARK: - LoadableNetworkFeeRowView

extension YieldFeeSection {
    struct LoadableFeeRowView: View {
        let leadingTitle: String
        let state: LoadableTextView.State
        let isHighlighted: Bool
        let leadingTextAccessoryView: LeadingTextAccessoryView

        init(
            leadingTitle: String,
            state: LoadableTextView.State,
            isHighlighted: Bool,
            leadingTextAccessoryView: LeadingTextAccessoryView
        ) {
            self.leadingTitle = leadingTitle
            self.state = state
            self.isHighlighted = isHighlighted
            self.leadingTextAccessoryView = leadingTextAccessoryView
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center) {
                    Text(leadingTitle)
                        .style(
                            Fonts.Regular.body,
                            color: isHighlighted ? DesignSystem.Color.textAccentRed : DesignSystem.Color.textPrimary
                        )

                    Spacer()

                    HStack {
                        leadingTextAccessoryView
                            .foregroundStyle(isHighlighted ? DesignSystem.Color.iconAccentRed : DesignSystem.Color.iconSecondary)

                        LoadableTextView(
                            state: state,
                            font: Fonts.Regular.body,
                            textColor: isHighlighted ? DesignSystem.Color.textAccentRed : DesignSystem.Color.textSecondary,
                            loaderSize: .init(width: 90, height: 20)
                        )
                    }
                }
            }
        }
    }
}

// MARK: - FooterText

extension YieldFeeSection {
    struct FooterText: View {
        let footerText: String
        let linkTitle: String?
        let url: URL?
        let isLinkActive: Bool
        let onLinkTapAction: (() -> Void)?

        var body: some View {
            let attr = makeFeePolicyAttributedString()

            return Text(attr)
                .environment(\.openURL, OpenURLAction { _ in
                    if let onLinkTapAction, isLinkActive {
                        onLinkTapAction()
                        return .handled
                    }

                    return .systemAction
                })
        }

        func makeFeePolicyAttributedString() -> AttributedString {
            var fullText: String

            if let linkTitle {
                fullText = "\(footerText) \(linkTitle)"
            } else {
                fullText = footerText
            }

            var attr = AttributedString(fullText)

            attr.font = Fonts.Regular.footnote
            attr.foregroundColor = DesignSystem.Color.textSecondary

            if let linkTitle, let range = attr.range(of: linkTitle) {
                attr[range].foregroundColor = isLinkActive ? DesignSystem.Color.textAccentBlue : DesignSystem.Color.textTertiary

                if let url {
                    attr[range].link = url
                } else if let emptyUrl = URL(string: " ") {
                    attr[range].link = emptyUrl
                }
            }

            return attr
        }
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 16) {
        YieldFeeSection(
            sectionState: .init(),
            leadingTitle: Localization.commonNetworkFeeTitle,
            feeSelector: YieldFeeSectionFeeSelector(
                viewModel: FeeCompactViewModel(
                    selectedFeeTokenCurrencySymbol: "USDT",
                    selectedFeeComponents: .loaded(text: "$1.45"),
                    canEditFee: true
                ),
                tapAction: {}
            )
        )

        YieldFeeSection(
            sectionState: .init(),
            leadingTitle: Localization.commonNetworkFeeTitle,
            feeSelector: YieldFeeSectionFeeSelector(
                viewModel: FeeCompactViewModel(selectedFeeComponents: .loading, canEditFee: true),
                tapAction: {}
            )
        )

        YieldFeeSection(
            sectionState: .init(),
            leadingTitle: Localization.commonNetworkFeeTitle,
            feeSelector: YieldFeeSectionFeeSelector(
                viewModel: FeeCompactViewModel(selectedFeeTokenCurrencySymbol: "ETH", selectedFeeComponents: .loaded(text: "$0.12")),
                tapAction: {}
            )
        )
    }
    .padding()
    .background(DesignSystem.Color.bgPrimary)
}
