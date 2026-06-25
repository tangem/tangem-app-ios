//
//  TangemSnackbar.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct TangemSnackbar: View, Setupable {
    private let title: String
    private let action: Action?

    private var icon: ImageType?
    private var iconColor: Color = .Tangem.Graphic.Neutral.secondary

    @ScaledMetric private var iconSize: CGFloat = .unit(.x5)
    @ScaledMetric private var rightLayoutHeight: CGFloat = .unit(.x11)

    public init(title: String, action: Action? = nil) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        ViewThatFits(in: .horizontal) {
            rightLayout
            bottomLayout
        }
        .background(Color.Tangem.Controls.backgroundDefault, in: shape)
    }
}

// MARK: - Layouts

private extension TangemSnackbar {
    var shape: some Shape {
        RoundedRectangle(cornerRadius: .unit(.x5), style: .continuous)
    }

    var rightLayout: some View {
        HStack(spacing: .unit(.x4)) {
            contentRow
                .lineLimit(1)

            if let action {
                actionButton(action)
            }
        }
        .padding(.leading, .unit(.x5))
        .padding(.trailing, action == nil ? .unit(.x5) : .unit(.x1))
        .frame(height: rightLayoutHeight)
    }

    var bottomLayout: some View {
        VStack(alignment: .trailing, spacing: 0) {
            contentRow
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, .unit(.x4))
                .padding(.trailing, .unit(.x3))

            if let action {
                actionButton(action)
            }
        }
        .padding(.leading, .unit(.x5))
        .padding(.trailing, .unit(.x2))
        .padding(.bottom, .unit(.x2))
    }

    var contentRow: some View {
        HStack(spacing: .unit(.x2)) {
            if let icon {
                icon.image
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: iconSize, height: iconSize)
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .style(Font.Tangem.Caption13.medium, color: Color.Tangem.Text.Neutral.secondary)
        }
    }

    func actionButton(_ action: Action) -> some View {
        TangemButton(
            content: .text(AttributedString(action.title)),
            action: action.handler
        )
        .setStyleType(.secondary)
        .setSize(.x9)
        .setCornerStyle(.rounded)
    }
}

// MARK: - Setupable

public extension TangemSnackbar {
    func icon(_ icon: ImageType?) -> Self {
        map { $0.icon = icon }
    }

    func iconColor(_ color: Color) -> Self {
        map { $0.iconColor = color }
    }
}

// MARK: - Action

public extension TangemSnackbar {
    struct Action {
        public let title: String
        public let handler: () -> Void

        public init(title: String, handler: @escaping () -> Void) {
            self.title = title
            self.handler = handler
        }
    }
}
