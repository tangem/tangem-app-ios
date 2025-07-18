//
//  HotBackupTypesView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct HotBackupTypesView: View {
    typealias ViewModel = HotBackupTypesViewModel

    let viewModel: ViewModel

    var body: some View {
        content
            .padding(.horizontal, 16)
            .background(Colors.Background.secondary.ignoresSafeArea())
            .navigationTitle(viewModel.navTitle)
    }
}

// MARK: - Subviews

private extension HotBackupTypesView {
    var content: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 8) {
                ForEach(viewModel.backupTypes) {
                    backupTypeView($0)
                }
            }
            .padding(.top, 16)
        }
    }

    func backupTypeView(_ item: ViewModel.BackupType) -> some View {
        Button(action: item.action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(item.title)
                        .style(Fonts.Bold.body, color: Colors.Text.primary1)

                    BadgeView(item: item.badge)
                }

                Text(item.description)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .background(Colors.Background.primary)
            .cornerRadius(14, corners: .allCorners)
        }
        .buttonStyle(.plain)
        .disabled(!item.isEnabled)
    }
}
