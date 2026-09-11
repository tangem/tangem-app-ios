//
//  MobileBackupUpgradeTypeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct MobileBackupUpgradeTypeView: View {
    typealias ViewModel = MobileBackupUpgradeTypeViewModel

    @ObservedObject var viewModel: ViewModel

    var body: some View {
        switch viewModel.item {
        case .some(let item): itemView(item)
        case .none: EmptyView()
        }
    }
}

// MARK: - Subviews

private extension MobileBackupUpgradeTypeView {
    func itemView(_ item: ViewModel.Item) -> some View {
        SwiftUI.Button(action: item.action) {
            HStack(spacing: 4) {
                info(item)
                chevronIcon
            }
            .padding(14)
            .background(Colors.Background.primary)
            .cornerRadius(14, corners: .allCorners)
        }
        .buttonStyle(.plain)
    }

    func info(_ item: ViewModel.Item) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            WrappingHStack(
                alignment: .leading,
                horizontalSpacing: 8,
                verticalSpacing: 4
            ) {
                Text(item.title)
                    .style(Fonts.Bold.body, color: Colors.Text.primary1)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                BadgeView(item: item.badge)
            }

            Text(item.description)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    var chevronIcon: some View {
        Assets.chevronRightWithOffset24.image
            .renderingMode(.template)
            .resizable()
            .foregroundStyle(Colors.Text.tertiary)
            .frame(width: 24, height: 24)
    }
}
