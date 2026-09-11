//
//  MobileBackupICloudTypeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct MobileBackupICloudTypeView: View {
    typealias ViewModel = MobileBackupICloudTypeViewModel

    @ObservedObject var viewModel: ViewModel

    var body: some View {
        switch viewModel.state {
        case .processing: processingState()
        case .done(let item): state(badge: item.badge, action: item.action)
        case .incomplete(let item): state(badge: item.badge, action: item.action)
        case .requirement(let item): state(badge: item.badge, action: item.action)
        case .unavailable(let item): unavailableState(item: item)
        case .none: EmptyView()
        }
    }
}

// MARK: - Subviews

private extension MobileBackupICloudTypeView {
    func processingState() -> some View {
        makeButton {
            VStack(alignment: .leading, spacing: 4) {
                titleView
                descriptionView
            }
            loader
        }
        .disabled(true)
    }

    func state(badge: BadgeView.Item, action: @escaping () -> Void) -> some View {
        makeButton(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                WrappingHStack(
                    alignment: .leading,
                    horizontalSpacing: 8,
                    verticalSpacing: 4
                ) {
                    titleView
                    makeBadge(badge)
                }

                descriptionView
            }

            chevronIcon
        }
    }

    func unavailableState(item: ViewModel.UnavailableItem) -> some View {
        makeButton(action: item.action) {
            VStack(alignment: .leading, spacing: 4) {
                titleView
                descriptionView
            }

            chevronIcon
        }
    }

    func makeButton<Content: View>(
        action: @escaping () -> Void = {},
        @ViewBuilder content: () -> Content
    ) -> some View {
        SwiftUI.Button(action: action) {
            HStack(spacing: 4) {
                content()
            }
            .padding(14)
            .background(DesignSystem.Color.bgSecondary)
            .cornerRadius(14, corners: .allCorners)
        }
        .buttonStyle(.plain)
    }

    func makeBadge(_ item: BadgeView.Item) -> some View {
        BadgeView(item: item)
    }

    var titleView: some View {
        Text(viewModel.title)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    var descriptionView: some View {
        Text(viewModel.description)
            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    var chevronIcon: some View {
        Assets.chevronRightWithOffset24.image
            .renderingMode(.template)
            .resizable()
            .foregroundStyle(Colors.Text.tertiary)
            .frame(width: 24, height: 24)
    }

    var loader: some View {
        Loader()
            .loaderSize(.size24)
            .loaderColor(DesignSystem.Color.iconPrimary)
    }
}
