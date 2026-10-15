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

    @ScaledMetric private var iconSize: CGFloat = 20
    @ScaledMetric private var rightLayoutHeight: CGFloat = 44

    public init(title: String, action: Action? = nil) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular, in: shape)
        } else {
            content
                .tangemMaterialSurface(in: shape)
        }
    }
}

// MARK: - Layouts

private extension TangemSnackbar {
    var content: some View {
        ViewThatFits(in: .horizontal) {
            rightLayout
            bottomLayout
        }
    }

    var shape: some InsettableShape {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
    }

    var rightLayout: some View {
        HStack(spacing: 16) {
            contentRow
                .lineLimit(1)

            if let action {
                actionButton(action)
            }
        }
        .padding(.leading, 20)
        .padding(.trailing, action == nil ? 20 : 12)
        .frame(height: rightLayoutHeight)
    }

    var bottomLayout: some View {
        VStack(alignment: .trailing, spacing: 0) {
            contentRow
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 16)
                .padding(.trailing, 12)

            if let action {
                actionButton(action)
            }
        }
        .padding(.leading, 20)
        .padding(.trailing, 8)
        .padding(.bottom, 8)
    }

    var contentRow: some View {
        HStack(spacing: 8) {
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
        .setSize(.x7)
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
