//
//  WelcomeV2View.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct WelcomeV2View: View {
    @ObservedObject var viewModel: WelcomeV2ViewModel

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            LinearGradient(
                stops: [
                    Gradient.Stop(color: .clear, location: 0.0),
                    Gradient.Stop(color: .black.opacity(0.35), location: 0.55),
                    Gradient.Stop(color: .black.opacity(0.85), location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                navigationBar
                    .padding(.horizontal, 16)
                    .frame(height: 44)

                Spacer(minLength: 0)

                titleBlock
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                LinearGradient(
                    colors: [.clear, .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 60)

                bottomContainer
            }
        }
        .preferredColorScheme(.dark)
    }

    private var navigationBar: some View {
        HStack {
            Assets.newTangemLogo.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 24)

            Spacer()
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Store all your assets")
                .style(Fonts.RegularStatic.title1, color: Colors.Text.primary1)

            Text("The only app you need\nto manage your finances")
                .style(Fonts.RegularStatic.body, color: Colors.Text.secondary)
        }
    }

    private var bottomContainer: some View {
        VStack(spacing: 12) {
            MainButton(
                title: "Create wallet",
                style: .primary,
                action: viewModel.onCreateWalletTap
            )

            MainButton(
                title: "I have a wallet",
                style: .secondary,
                action: viewModel.onExistingWalletTap
            )

            footer
                .padding(.horizontal, 24)
        }
        .padding(.horizontal, 16)
        .padding(.top, 15)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .background {
            Rectangle()
                .fill(Color.black)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private var footer: some View {
        Text("By continuing, you agree with Terms of service and Privacy Policy")
            .style(Fonts.RegularStatic.caption1, color: Colors.Text.tertiary)
            .multilineTextAlignment(.center)
    }
}

// MARK: - Previews

#Preview {
    WelcomeV2View(viewModel: WelcomeV2ViewModel(coordinator: WelcomeV2Coordinator()))
}
