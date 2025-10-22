//
//  TangemPayCardDetailsView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct TangemPayCardDetailsView: View {
    @ObservedObject var viewModel: TangemPayCardDetailsViewModel

    var body: some View {
        VStack(spacing: 22) {
            HStack {
                // [REDACTED_TODO_COMMENT]
                Text("Card Details")
                    .style(
                        Fonts.Bold.footnote,
                        color: Colors.Text.tertiary
                    )

                Spacer()

                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.6)
                        .opacity(viewModel.state.isLoading ? 1 : 0)

                    // [REDACTED_TODO_COMMENT]
                    Button(
                        viewModel.state.isLoaded ? "Hide" : "Reveal",
                        action: viewModel.toggleVisibility
                    )
                    .style(
                        Fonts.Regular.footnote,
                        color: viewModel.state.isLoading ? Colors.Text.disabled : Colors.Text.accent
                    )
                    .disabled(viewModel.state.isLoading)
                }
                .animation(.easeInOut(duration: 0.4), value: viewModel.state.isLoaded)
            }

            VStack(spacing: 8) {
                field(text: viewModel.cardDetailsData.number, copyAction: viewModel.copyNumber)
                HStack(spacing: 12) {
                    field(text: viewModel.cardDetailsData.expirationDate, copyAction: viewModel.copyExpirationDate)
                    field(text: viewModel.cardDetailsData.cvc, copyAction: viewModel.copyCVC)
                }
            }
            .padding(.bottom, 2)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Colors.Background.primary)
        .cornerRadius(14)
    }

    private func field(text: String, copyAction: @escaping () -> Void) -> some View {
        HStack {
            Text(text)
                .style(
                    Fonts.Regular.subheadline,
                    color: viewModel.state.isLoaded ? Colors.Text.primary1 : Colors.Text.tertiary
                )

            Spacer()

            Button(action: copyAction) {
                Assets.copyNew.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(size: .init(bothDimensions: 24))
            }
            .disabled(!viewModel.state.isLoaded)
            .opacity(viewModel.state.isLoaded ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .background(Colors.Field.primary)
        .cornerRadius(14)
        .animation(.easeInOut(duration: 0.4), value: viewModel.cardDetailsData)
    }
}
