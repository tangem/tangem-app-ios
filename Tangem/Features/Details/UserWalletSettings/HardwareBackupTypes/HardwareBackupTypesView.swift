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
            .padding(16)
            .navigationTitle(viewModel.navigationTitle)
            .background(Colors.Background.secondary)
            .onFirstAppear(perform: viewModel.onFirstAppear)
            .alert(item: $viewModel.alert) { $0.alert }
    }
}

// MARK: - Content

private extension HardwareBackupTypesView {
    var content: some View {
        VStack(spacing: 0) {
            backupTypes

            Spacer()

            buyButton(item: viewModel.buyItem)
        }
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
            if #available(iOS 16.0, *) {
                WrappingHStack(
                    alignment: .leading,
                    horizontalSpacing: 8,
                    verticalSpacing: 4
                ) {
                    backupTypeInfoHeader(title: item.title, badge: item.badge)
                }
            } else {
                HStack(alignment: .top, spacing: 8) {
                    backupTypeInfoHeader(title: item.title, badge: item.badge)
                }
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

    func buyButton(item: ViewModel.BuyItem) -> some View {
        HStack(spacing: 0) {
            Text(item.title)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 22)

            Button(action: item.buttonAction) {
                Text(item.buttonTitle)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Colors.Button.secondary)
                    .cornerRadius(24, corners: .allCorners)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Colors.Background.primary)
        .cornerRadius(14, corners: .allCorners)
    }
}
