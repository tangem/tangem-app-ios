//
//  MobileOnboardingImportICloudBackupListView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets

struct MobileOnboardingImportICloudBackupListView: View {
    typealias ViewModel = MobileOnboardingImportICloudBackupListViewModel

    @ObservedObject var viewModel: ViewModel

    var body: some View {
        content
            .background(Appearance.backgroundColor)
            .stepsFlowNavBar(title: viewModel.navigationTitle)
            .stepsFlowNavBar(leading: { navigationBackButton })
            .stepsFlowNavBar(backgroundColor: Appearance.backgroundColor)
            .onAppear(perform: viewModel.onAppear)
    }
}

// MARK: - Subviews

private extension MobileOnboardingImportICloudBackupListView {
    var content: some View {
        ScrollView(.vertical) {
            VStack(spacing: Layout.itemsSpacing) {
                ForEach(indexed: viewModel.items, id: \.0) { _, item in
                    itemView(item)
                }

                if viewModel.isHintVisible {
                    hintView
                }
            }
            .padding(.horizontal, Layout.itemsHorizontalPadding)
            .padding(.vertical, Layout.itemsVerticalPadding)
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    func itemView(_ item: ViewModel.Item) -> some View {
        switch item.state {
        case .available(let action):
            Row(title: item.title, subtitle: item.description)
                .start { availableItemLeadingIcon }
                .end { availableItemTrailingIcon }
                .onTap(action: action)
                .background(Appearance.itemBackgroundColor, in: itemBackgroundShape)
        case .added(let badgeTitle):
            Row(title: item.title, subtitle: item.description)
                .overrideTextColors(Appearance.addedItemTextColors)
                .start { addedItemLeadingIcon }
                .end { addedItemBadge(title: badgeTitle) }
                .background(Appearance.itemBackgroundColor, in: itemBackgroundShape)
        }
    }

    var hintView: some View {
        Text(viewModel.hint)
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    var itemBackgroundShape: some Shape {
        RoundedRectangle(cornerRadius: Layout.itemBackgroundCornerRadius)
    }

    var navigationBackButton: some View {
        MobileOnboardingFlowNavBarAction.back(handler: viewModel.onBackTap).view()
    }

    var availableItemLeadingIcon: some View {
        Avatar(.icon(DesignSystem.Icons.Cloud.filled20, appearance: .info))
    }

    var availableItemTrailingIcon: some View {
        DesignSystem.Icons.ChevronRight.regular20.image
            .renderingMode(.template)
            .foregroundStyle(DesignSystem.Color.iconSecondary)
    }

    var addedItemLeadingIcon: some View {
        Avatar(.icon(DesignSystem.Icons.Cloud.filled20, appearance: .neutral))
    }

    func addedItemBadge(title: String) -> some View {
        Badge(label: title, accessibilityLabel: nil)
            .layoutPriority(1)
    }
}

// MARK: - Constants

private extension MobileOnboardingImportICloudBackupListView {
    enum Layout {
        static let itemsSpacing: CGFloat = 8
        static let itemsHorizontalPadding: CGFloat = 16
        static let itemsVerticalPadding: CGFloat = 12
        static let itemBackgroundCornerRadius: CGFloat = 24
    }

    enum Appearance {
        static let backgroundColor: Color = DesignSystem.Color.bgPrimary
        static let itemBackgroundColor: Color = DesignSystem.Color.bgSecondary
        static let addedItemTextColors = RowOverrideTextColors(
            title: DesignSystem.Color.textSecondary,
            subtitle: DesignSystem.Color.textSecondary
        )
    }
}
