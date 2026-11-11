//
//  OnrampRedirectingView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Kingfisher
import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct OnrampRedirectingView: View {
    @ObservedObject var viewModel: OnrampRedirectingViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            DesignSystem.Color.bgPrimary.ignoresSafeArea()

            ModalStatus(
                title: Localization.onrampRedirectingToProviderTitle(viewModel.providerName),
                description: Localization.onrampRedirectingToProviderSubtitle(viewModel.providerName)
            ) {
                assets
            }
        }
        .navigationTitle(Text(viewModel.title))
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $viewModel.alert) { $0.alert }
        .onAppear {
            viewModel.update(colorScheme: colorScheme)
        }
        .onChange(of: colorScheme) { viewModel.update(colorScheme: $0) }
        .task { await viewModel.loadRedirectData() }
    }

    private var assets: some View {
        HStack(spacing: 12) {
            Avatar(.icon(DesignSystem.Icons.LogoTangem.regular32), size: .size72)

            Loader()
                .loaderSize(.size20)

            ProviderLogoAvatar(url: viewModel.providerImageURL)
                .id(viewModel.providerImageURL)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - ProviderLogoAvatar

private struct ProviderLogoAvatar: View {
    let url: URL?

    @State private var loadingState: LoadingState = .loading

    var body: some View {
        Avatar(.address(nil), size: .size72)
            .environment(\.isShimmerActive, url != nil && loadingState == .loading)
            .opacity(loadingState == .loaded ? 0 : 1)
            .overlay {
                if let url {
                    KFImage(url)
                        .onSuccess { _ in loadingState = .loaded }
                        .onFailure { _ in loadingState = .failed }
                        .cancelOnDisappear(true)
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                }
            }
    }
}

private extension ProviderLogoAvatar {
    enum LoadingState {
        case loading
        case loaded
        case failed
    }
}
