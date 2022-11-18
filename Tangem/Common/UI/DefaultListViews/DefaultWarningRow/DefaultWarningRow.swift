//
//  DefaultWarningRow.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct DefaultWarningRow: View {
    private let viewModel: DefaultWarningRowViewModel

    init(viewModel: DefaultWarningRowViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Button(action: viewModel.action) {
            HStack(alignment: .center, spacing: 12) {
                viewModel.icon
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding(8)
                    .background(Colors.Background.secondary)
                    .cornerRadius(40)

                VStack(alignment: .leading, spacing: 4) {
                    if let title = viewModel.title {
                        Text(title)
                            .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                    }

                    Text(viewModel.subtitle)
                        .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                detailsView
            }
            .padding(.vertical, 16)
            .background(Colors.Background.primary)
            .contentShape(Rectangle())
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private var detailsView: some View {
        Group {
            switch viewModel.detailsType {
            case .none:
                EmptyView()
            case .icon(let image):
                image
                    .resizable()
                    .frame(width: 20, height: 20)
            case .loader:
                ProgressViewCompat(color: Colors.Icon.informative)
                    .frame(width: 20, height: 20)
            }
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 14)
        .background(Colors.Button.secondary)
        .cornerRadius(10)
    }
}

struct DefaultWarningRow_Preview: PreviewProvider {
    static let viewModel = DefaultWarningRowViewModel(
        icon: Assets.attention,
        title: "Enable biometric authentication",
        subtitle: "Not enough funds for fee on your Polygon wallet to create a transaction. Top up your Polygon wallet first.",
        detailsType: .icon(Assets.refreshWarningIcon),
        action: {}
    )

    static var previews: some View {
        ZStack {
            Colors.Background.secondary

            DefaultWarningRow(viewModel: viewModel)
                .padding(.horizontal, 16)
        }
    }
}
