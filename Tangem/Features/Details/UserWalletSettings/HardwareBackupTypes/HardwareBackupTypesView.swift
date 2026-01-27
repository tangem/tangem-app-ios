//
//  HardwareBackupTypesView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct HardwareBackupTypesView: View {
    typealias ViewModel = HardwareBackupTypesViewModel

    @ObservedObject var viewModel: ViewModel

    var body: some View {
        content
            .padding(.horizontal, 16)
            .navigationTitle(viewModel.navigationTitle)
            .background(Colors.Background.secondary)
            .onFirstAppear(perform: viewModel.onFirstAppear)
            .alert(item: $viewModel.alert) { $0.alert }
    }
}

// MARK: - Content

private extension HardwareBackupTypesView {
    var content: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 8) {
                info(item: viewModel.infoItem)
                backupTypes
            }
            .padding(.top, 16)
        }
    }

    func info(item: ViewModel.InfoItem) -> some View {
        VStack(spacing: 0) {
            Text(item.title)
                .style(Fonts.Bold.title2, color: Colors.Text.primary1)
                .padding(.horizontal, 24)

            Text(item.description)
                .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
                .padding(.horizontal, 24)

            HorizontalFlowLayout(
                items: item.chips,
                alignment: .center,
                horizontalSpacing: 16,
                verticalSpacing: 8,
                itemContent: infoChip
            )
            .padding(.top, 16)

            item.icon.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 124, height: 124)
                .padding(.top, 4)

            MainButton(
                title: item.action.title,
                style: .secondary,
                action: item.action.handler
            )
            .padding(.top, 4)
        }
        .padding(EdgeInsets(top: 24, leading: 14, bottom: 16, trailing: 14))
        .background(Colors.Background.primary)
        .cornerRadius(14, corners: .allCorners)
        .colorScheme(.dark)
    }

    var backupTypes: some View {
        VStack(spacing: 8) {
            ForEach(viewModel.backupItems) { item in
                backupType(item: item)
            }
        }
    }
}

// MARK: - Subviews

private extension HardwareBackupTypesView {
    func infoChip(item: ViewModel.InfoChipItem) -> some View {
        HStack(alignment: .top, spacing: 6) {
            item.icon.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Colors.Icon.accent)
                .frame(width: 16, height: 16)

            Text(item.title)
                .style(Fonts.Bold.footnote, color: Colors.Text.secondary)
                .multilineTextAlignment(.center)
        }
    }

    func backupType(item: ViewModel.BackupItem) -> some View {
        Button(action: item.action) {
            HStack(spacing: 4) {
                backupTypeInfo(item: item)

                Assets.chevronRightWithOffset24.image
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(Colors.Text.tertiary)
                    .frame(width: 24, height: 24)
            }
            .padding(14)
            .background(Colors.Background.primary)
            .cornerRadius(14, corners: .allCorners)
        }
        .buttonStyle(.plain)
    }

    func backupTypeInfo(item: ViewModel.BackupItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            WrappingHStack(
                alignment: .leading,
                horizontalSpacing: 8,
                verticalSpacing: 4
            ) {
                backupTypeInfoHeader(title: item.title, badge: item.badge)
            }

            Text(item.description)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    func backupTypeInfoHeader(title: String, badge: BadgeView.Item?) -> some View {
        Group {
            Text(title)
                .style(Fonts.Bold.body, color: Colors.Text.primary1)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            badge.map {
                BadgeView(item: $0)
            }
        }
    }
}
