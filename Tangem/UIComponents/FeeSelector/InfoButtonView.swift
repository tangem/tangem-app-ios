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

@available(iOS 16.4, *)
struct InfoButtonView: View {
    @State private var isTooltipShowing: Bool = false
    @State private var tooltipSize: CGSize = .zero

    private let size: Size
    private let tooltipText: String

    init(size: Size, tooltipText: String) {
        self.size = size
        self.tooltipText = tooltipText
    }

    var body: some View {
        Button(action: { isTooltipShowing = true }) {
            size.icon.image
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(Colors.Icon.informative)
                .frame(size: size.iconSize)
        }
        .popover(tooltipText, isPresented: $isTooltipShowing)
    }
}

@available(iOS 16.4, *)
extension InfoButtonView {
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
