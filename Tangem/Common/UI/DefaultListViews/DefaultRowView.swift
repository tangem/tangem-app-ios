//
//  DefaultRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct DefaultRowView: View {
    let title: String
    let detailsType: DetailsType?
    let action: (() -> Void)?

    private var isTappable: Bool { action != nil }

    /// - Parameters:
    ///   - title: Leading one line title
    ///   - details: Trailing one line text
    ///   - action: If the `action` is set that the row will be tappable and have chevron icon
    init(
        title: String,
        detailsType: DetailsType? = .none,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.detailsType = detailsType
        self.action = action
    }

    var body: some View {
        Button(action: { action?() }) {
            HStack {
                Text(title)
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
        switch detailsType {
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

extension DefaultRowView {
    enum DetailsType {
        case text(_ string: String)
        case loader
    }
}
