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
            .onFirstAppear(perform: viewModel.onFirstAppear)
            .alert(item: $viewModel.alert) { $0.alert }
    }
}

// MARK: - Subviews

private extension MobileBackupTypesView {
    var content: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                ForEach(viewModel.sections) {
                    section(model: $0)
                }
            }
            .padding(.top, 16)
        }
    }

    func section(model: ViewModel.Section) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            model.title.map {
                Text($0)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                    .padding(.leading, 14)
            }

            VStack(spacing: 8) {
                ForEach(model.items) {
                    sectionItem(model: $0)
                }
            }
        }
    }

    func sectionItem(model: ViewModel.SectionItem) -> some View {
        Button(action: model.action) {
            HStack(spacing: 4) {
                sectionInfoItem(model: model)

                if model.isEnabled {
                    Assets.chevronRightWithOffset24.image
                        .renderingMode(.template)
                        .resizable()
                        .foregroundStyle(Colors.Text.tertiary)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(14)
            .background(Colors.Background.primary)
            .cornerRadius(14, corners: .allCorners)
        }
        .buttonStyle(.plain)
        .disabled(!model.isEnabled)
    }

    func sectionInfoItem(model: ViewModel.SectionItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            WrappingHStack(
                alignment: .leading,
                horizontalSpacing: 8,
                verticalSpacing: 4
            ) {
                sectionInfo(title: model.title, badge: model.badge)
            }

            Text(model.description)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    func sectionInfo(title: String, badge: BadgeView.Item?) -> some View {
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
