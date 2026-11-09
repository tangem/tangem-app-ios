//
//  TOSView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets

struct TOSView: View {
    @ObservedObject var viewModel: TOSViewModel

    var body: some View {
        WebViewContainer(viewModel: viewModel.webViewModel)
            .overlay(bottomOverlay)
            .edgesIgnoringSafeArea(.bottom)
    }

    @ViewBuilder
    private var bottomOverlay: some View {
        VStack {
            Spacer()
            LinearGradient(
                colors: [
                    DesignSystem.Color.bgSecondary.opacity(0),
                    DesignSystem.Color.bgSecondary,
                    DesignSystem.Color.bgSecondary,
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(maxHeight: viewModel.bottomOverlayHeight)
            .allowsHitTesting(false)
        }
    }
}

#Preview {
    TOSView(viewModel: .init())
}
