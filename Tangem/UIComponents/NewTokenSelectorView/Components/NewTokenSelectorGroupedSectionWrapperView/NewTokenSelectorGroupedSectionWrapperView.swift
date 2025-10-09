//
//  NewTokenSelectorGroupedSectionWrapperView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct NewTokenSelectorGroupedSectionWrapperView: View {
    @ObservedObject var viewModel: NewTokenSelectorGroupedSectionWrapperViewModel
    let shouldShowSeparator: Bool

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut) {
                viewModel.isOpen.toggle()
            }
        }) {
            HStack(spacing: .zero) {
                Text(viewModel.wallet)
                    .style(Fonts.Bold.headline, color: Colors.Text.primary1)

                Spacer(minLength: 8)

                CircleButton.back(action: {})
                    .allowsHitTesting(false)
                    .rotationEffect(.degrees(180))
                    .rotationEffect(.degrees(viewModel.isOpen ? 90 : -90))
            }
            .padding(.horizontal, 8)
        }

        if viewModel.isOpen {
            ForEach(viewModel.sections) {
                NewTokenSelectorGroupedSectionView(viewModel: $0)
            }
        } else if shouldShowSeparator {
            Separator(color: Colors.Stroke.primary)
        }
    }
}
