//
//  OnrampRedirectingView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

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
        .task { await viewModel.loadProviderLogo() }
    }

    private var assets: some View {
        HStack(spacing: 12) {
            Avatar(.icon(DesignSystem.Icons.LogoTangem.regular32), size: .size72)

            Loader()
                .loaderSize(.size20)

            providerAvatar
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var providerAvatar: some View {
        switch viewModel.providerLogo {
        case .loading:
            Avatar(.address(nil), size: .size72)
                .environment(\.isShimmerActive, true)
        case .loaded(let image):
            Avatar(.asset(image), size: .size72)
        case .unavailable:
            Avatar(.address(nil), size: .size72)
        }
    }
}
