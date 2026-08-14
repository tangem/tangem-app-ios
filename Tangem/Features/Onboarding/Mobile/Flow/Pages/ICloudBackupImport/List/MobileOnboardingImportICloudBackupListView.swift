//
//  MobileOnboardingImportICloudBackupListView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
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
    }
}

// MARK: - Subviews

private extension MobileOnboardingImportICloudBackupListView {
    var content: some View {
        ScrollView(.vertical) {
            VStack(spacing: Layout.itemsSpacing) {
                ForEach(Array(viewModel.items.enumerated()), id: \.offset) { _, item in
                    itemView(item)
                }
            }
            .padding(.horizontal, Layout.itemsHorizontalPadding)
            .padding(.vertical, Layout.itemsVerticalPadding)
        }
        .scrollIndicators(.hidden)
    }

    func itemView(_ item: ViewModel.Item) -> some View {
        Row(title: item.title, subtitle: item.description)
            .start { itemLeadingIcon }
            .end { itemTrailingIcon }
            .onTap(item.action)
            .background(Appearance.itemBackgroundColor, in: itemBackgroundShape)
    }

    var itemBackgroundShape: some Shape {
        RoundedRectangle(cornerRadius: Layout.itemBackgroundCornerRadius)
    }

    var navigationBackButton: some View {
        MobileOnboardingFlowNavBarAction.back(handler: viewModel.onBackTap).view()
    }

    var itemLeadingIcon: some View {
        ZStack {
            Circle()
                .fill(DesignSystem.Color.bgStatusInfoSubtle)
                .frame(size: CGSize(bothDimensions: Layout.itemLeadingIconSide))

            DesignSystem.Icons.Cloud.filled20.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconBrand)
        }
    }

    var itemTrailingIcon: some View {
        DesignSystem.Icons.ChevronRight.regular20.image
            .renderingMode(.template)
            .foregroundStyle(DesignSystem.Color.iconSecondary)
    }
}

// MARK: - Constants

private extension MobileOnboardingImportICloudBackupListView {
    enum Layout {
        static let itemsSpacing: CGFloat = 8
        static let itemsHorizontalPadding: CGFloat = 16
        static let itemsVerticalPadding: CGFloat = 12
        static let itemBackgroundCornerRadius: CGFloat = 24
        static let itemLeadingIconSide: CGFloat = 40
    }

    enum Appearance {
        static let backgroundColor: Color = DesignSystem.Color.bgPrimary
        static let itemBackgroundColor: Color = DesignSystem.Color.bgSecondary
    }
}
