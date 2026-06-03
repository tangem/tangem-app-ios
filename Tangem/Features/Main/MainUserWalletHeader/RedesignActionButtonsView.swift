//
//  RedesignActionButtonsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemAccessibilityIdentifiers

struct RedesignActionButtonsView: View {
    @ObservedObject var viewModel: ActionButtonsViewModel

    @State private var widestButtonWidth: CGFloat?

    var body: some View {
        HStack(spacing: SizeUnit.x6.value) {
            RedesignActionButtonView(viewModel: viewModel.buyActionButtonViewModel)
                .fixedSize(horizontal: true, vertical: false)
                .onGeometryChange(for: CGFloat.self, of: \.size.width, action: updateWidestButtonWidth)
                .frame(width: widestButtonWidth)

            RedesignActionButtonView(viewModel: viewModel.swapActionButtonViewModel)
                .fixedSize(horizontal: true, vertical: false)
                .onGeometryChange(for: CGFloat.self, of: \.size.width, action: updateWidestButtonWidth)
                .frame(width: widestButtonWidth)

            RedesignActionButtonView(viewModel: viewModel.sellActionButtonViewModel)
                .fixedSize(horizontal: true, vertical: false)
                .onGeometryChange(for: CGFloat.self, of: \.size.width, action: updateWidestButtonWidth)
                .frame(width: widestButtonWidth)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(TokenAccessibilityIdentifiers.actionButtonsList)
    }

    private func updateWidestButtonWidth(to width: CGFloat) {
        let newWidth = max(widestButtonWidth ?? .zero, width)
        guard newWidth > 0 else { return }

        widestButtonWidth = newWidth
    }
}
