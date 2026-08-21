//
//  WelcomeHardwareWalletView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// [REDACTED_TODO_COMMENT]
struct WelcomeHardwareWalletView: View {
    @ObservedObject var viewModel: WelcomeHardwareWalletViewModel

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                Spacer()

                titleBlock
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)

                buttons
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
        }
        .preferredColorScheme(.dark)
        .alert(item: $viewModel.alert, content: { $0.alert })
        .fullScreenCover(item: $viewModel.shopWebViewModel) { webViewModel in
            WebViewContainer(viewModel: webViewModel)
        }
    }

    private var topBar: some View {
        HStack {
            Spacer()

            Button(action: viewModel.onCloseTap) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.12), in: Circle())
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("One wallet, multiple cards")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)

            Text("Use any of your cards to access your wallet")
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var buttons: some View {
        VStack(spacing: 12) {
            Button(action: viewModel.onLearnMoreTap) {
                Text("Learn more or buy")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Color.white.opacity(0.12), in: Capsule())
            }
            .disabled(viewModel.isScanning)

            Button(action: viewModel.onScanTap) {
                HStack(spacing: 8) {
                    Text("Scan your wallet")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)

                    Assets.tangemIcon.image
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Color.white, in: Capsule())
            }
            .disabled(viewModel.isScanning)
        }
    }
}
