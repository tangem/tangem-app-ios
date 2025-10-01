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

    var body: some View {
        HStack(spacing: .zero) {
            Button(action: { viewModel.isOpen.toggle() }) {
                Text(viewModel.wallet)
                    .style(Fonts.Bold.headline, color: Colors.Text.primary1)
            }

            Spacer(minLength: 8)

            CircleButton.back(action: {})
                .rotationEffect(.degrees(90))
        }

        ForEach(viewModel.sections) {
            NewTokenSelectorGroupedSectionView(viewModel: $0)
        }
    }
}
