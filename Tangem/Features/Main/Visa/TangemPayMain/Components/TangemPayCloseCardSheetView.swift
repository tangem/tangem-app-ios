//
//  TangemPayCloseCardSheetView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct TangemPayCloseCardSheetView: View {
    @ObservedObject var viewModel: TangemPayCloseCardSheetViewModel

    var body: some View {
        VStack(spacing: 24) {
            viewModel.icon
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(size: .init(bothDimensions: 56))
                .padding(.top, 48)

            VStack(spacing: 8) {
                Text(viewModel.title)
                    .style(Fonts.Bold.title3, color: Colors.Text.primary1)

                Text(viewModel.description)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
            }
            .padding(.bottom, 16)

            VStack(spacing: 8) {
                MainButton(settings: viewModel.primaryButton)
                MainButton(settings: viewModel.secondaryButton)
            }
        }
        .overlay(alignment: .topTrailing) {
            NavigationBarButton.close(action: viewModel.dismiss)
        }
        .floatingSheetConfiguration { config in
            config.backgroundInteractionBehavior = .tapToDismiss
        }
        .padding(16)
        .frame(maxWidth: .infinity)
    }
}
