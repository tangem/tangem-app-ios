//
//  RoundedButton.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct RoundedButton: View {
    private let style: Style
    private let action: () -> Void

    private var disabled: Bool = false

    @State private var size: CGSize = .zero

    public init(title: String, action: @escaping () -> Void) {
        style = .string(title)
        self.action = action
    }

    public init(image: ImageType, action: @escaping () -> Void) {
        style = .icon(image)
        self.action = action
    }

    public init(style: Style, action: @escaping () -> Void) {
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            content
                .background {
                    RoundedRectangle(cornerRadius: size.height / 2)
                        .fill(Colors.Button.secondary)
                }
                .readGeometry(\.size, bindTo: $size)
        }
        .disabled(disabled)
    }

    @ViewBuilder
    public var content: some View {
        switch style {
        case .string(let string):
            Text(.init(string))
                .style(Fonts.Bold.footnote, color: disabled ? Colors.Text.disabled : Colors.Text.primary1)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        case .icon(let imageType, let color):
            imageType.image
                .resizable()
                .renderingMode(.template)
                .frame(width: 20, height: 20)
                .foregroundStyle(color)
                .padding(.all, 4)
        }
    }
}

// MARK: - Setupable

extension RoundedButton: Setupable {
    public func disabled(_ disabled: Bool) -> Self {
        map { $0.disabled = disabled }
    }
}

public extension RoundedButton {
    enum Style: Hashable {
        case string(String)
        case icon(ImageType, color: Color = Colors.Icon.primary1)
    }
}
