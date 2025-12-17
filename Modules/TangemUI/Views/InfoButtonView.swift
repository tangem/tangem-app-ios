//
//  InfoButtonView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct InfoButtonView: View {
    @State private var isTooltipShowing: Bool = false
    @State private var tooltipSize: CGSize = .zero

    private let size: Size
    private let tooltipText: PopoverModifier.TextType

    private var color: Color = Colors.Icon.informative

    public init(size: Size, tooltipText: String) {
        self.size = size
        self.tooltipText = .rich(text: tooltipText)
    }

    public init(size: Size, tooltipText: AttributedString) {
        self.size = size
        self.tooltipText = .attributed(text: tooltipText)
    }

    public init(size: Size, tooltipText: PopoverModifier.TextType) {
        self.size = size
        self.tooltipText = tooltipText
    }

    public var body: some View {
        Button(action: { isTooltipShowing = true }) {
            size.icon.image
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(color)
                .frame(size: size.iconSize)
        }
        .popover(tooltipText, isPresented: $isTooltipShowing)
    }
}

// MARK: - Setupable

extension InfoButtonView: Setupable {
    public func color(_ color: Color) -> Self {
        map { $0.color = color }
    }
}

public extension InfoButtonView {
    enum Size {
        case small
        case medium

        var icon: ImageType {
            switch self {
            case .small: Assets.infoCircle16
            case .medium: Assets.infoCircle20
            }
        }

        var iconSize: CGSize {
            switch self {
            case .small: CGSize(width: 16, height: 16)
            case .medium: CGSize(width: 20, height: 20)
            }
        }
    }
}
