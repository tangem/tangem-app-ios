//
//  MobileBackupTypesView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct MobileBackupTypesView: View {
    typealias ViewModel = MobileBackupTypesViewModel

    @ObservedObject var viewModel: ViewModel

    var body: some View {
        content
            .padding(.horizontal, 16)
            .background(Colors.Background.secondary.ignoresSafeArea())
            .navigationTitle(viewModel.navTitle)
            .alert(item: $viewModel.alert) { $0.alert }
    }
}

// MARK: - Subviews

private extension MobileBackupTypesView {
    var content: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                ForEach(viewModel.sections) {
                    sectionView(model: $0)
                }
            }
            .padding(.top, 16)
        }
    }

    func sectionView(model: ViewModel.Section) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            model.title.map {
                Text($0)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                    .padding(.leading, 14)
            }

            VStack(spacing: 8) {
                ForEach(model.items) {
                    itemView(model: $0)
                }
            }
        }
    }

    func itemView(model: ViewModel.Item) -> some View {
        Button(action: model.action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(model.title)
                        .style(Fonts.Bold.body, color: Colors.Text.primary1)

                    model.badge.map {
                        BadgeView(item: $0)
                    }
                }

                Text(model.description)
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
        .disabled(!model.isEnabled)
    }
}
