//
//  TangemPayComparePlansSheetView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemUI
import TangemUIUtils

struct TangemPayComparePlansSheetView: View {
    let viewModel: TangemPayComparePlansSheetViewModel

    @State private var introspectionID = UUID()

    var body: some View {
        VStack(spacing: 0) {
            FloatingSheetNavigationBarView(
                title: viewModel.title,
                backgroundColor: DesignSystem.Color.bgPrimary,
                closeButtonAction: viewModel.close
            )

            ScrollView(showsIndicators: false) {
                VStack(spacing: Constants.sectionSpacing) {
                    ForEach(viewModel.sections) { section in
                        sectionView(section)
                    }
                }
                .padding(.horizontal, Constants.horizontalPadding)
                .padding(.top, Constants.contentTopPadding)
                .padding(.bottom, Constants.contentBottomPadding)
            }
            .introspectResponderChain(
                introspectedType: UIScrollView.self,
                includeSubviews: true,
                updateOnChangeOf: introspectionID
            ) { scrollView in
                viewModel.scrollState.scrollView = scrollView

                if let offset = viewModel.scrollState.pendingRestoreOffset {
                    viewModel.scrollState.pendingRestoreOffset = nil
                    DispatchQueue.main.async {
                        scrollView.adjustedContentOffset = offset
                    }
                }
            }
            .onDidAppear {
                introspectionID = UUID()
            }
            .onDisappear {
                viewModel.scrollState.pendingRestoreOffset = viewModel.scrollState.scrollView?.adjustedContentOffset
            }
        }
        .floatingSheetConfiguration { configuration in
            configuration.maxHeightFraction = Constants.maxHeightFraction
            configuration.sheetBackgroundColor = DesignSystem.Color.bgPrimary
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
        .environment(\.openURL, OpenURLAction { url in
            viewModel.openURL(url)
            return .handled
        })
    }

    private func sectionView(_ section: TangemPayComparePlansSheetViewModel.ComparisonSection) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(section.title)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.comparePlansSection(section.title))

            VStack(spacing: 0) {
                ForEach(Array(section.rows.enumerated()), id: \.element.id) { index, row in
                    rowView(row, isStacked: section.isStacked, showDivider: index < section.rows.count - 1)
                }
            }
            .background(DesignSystem.Color.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Constants.cardCornerRadius, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func rowView(
        _ row: TangemPayComparePlansSheetViewModel.Row,
        isStacked: Bool,
        showDivider: Bool
    ) -> some View {
        if isStacked {
            Row(subtitle: row.planName)
                .titleAccessory {
                    Text(row.value)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                        .multilineTextAlignment(.leading)
                }
                .lineOrder(.secondaryFirst)
                .showDivider(showDivider)
                .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.comparePlansRow(row.planName))
        } else {
            Row(title: row.planName)
                .valueAccessory {
                    Text(row.value)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                        .multilineTextAlignment(.trailing)
                }
                .contentLead(.end)
                .overrideTextColors(.init(title: DesignSystem.Color.textSecondary))
                .showDivider(showDivider)
                .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.comparePlansRow(row.planName))
        }
    }
}

private extension TangemPayComparePlansSheetView {
    enum Constants {
        static let maxHeightFraction: CGFloat = 0.9
        static let sectionSpacing: CGFloat = 24
        static let horizontalPadding: CGFloat = 16
        static let contentTopPadding: CGFloat = 12
        static let contentBottomPadding: CGFloat = 32
        static let cardCornerRadius: CGFloat = 24
    }
}
