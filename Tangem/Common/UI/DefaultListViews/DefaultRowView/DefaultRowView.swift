//
//  DefaultRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct DefaultRowView: View {
    private let viewModel: DefaultRowViewModel

    init(viewModel: DefaultRowViewModel) {
        self.viewModel = viewModel
    }

    private var isTappable: Bool { viewModel.action != nil }

    var body: some View {
        Button(action: { viewModel.action?() }) {
            HStack {
                Text(viewModel.title)
                    .style(Fonts.Regular.body, color: Colors.Text.primary1)

                Spacer()

                detailsView

                if isTappable {
                    Assets.chevron
                }
            }
            .lineLimit(1)
        }
        .disabled(!isTappable)
    }

    @ViewBuilder
    private var detailsView: some View {
        switch viewModel.detailsType {
        case .none:
            EmptyView()
        case .loader:
            ActivityIndicatorView(style: .medium, color: .gray)
        case let .text(string):
            Text(string)
                .style(Fonts.Regular.body, color: Colors.Text.tertiary)
                .layoutPriority(1)
        }
    }
}
