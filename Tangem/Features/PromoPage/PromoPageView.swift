//
//  PromoPageView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct PromoPageView: View {
    @ObservedObject var viewModel: PromoPageViewModel

    var body: some View {
        ZStack {
            WebView(
                url: viewModel.url,
                allowsJavaScript: true,
                restrictedLoading: WebView.RestrictedLoading(
                    isAllowed: viewModel.allowsNavigation(to:),
                    onFirstContent: viewModel.pageDidFinishLoading,
                    onInitialLoadFailure: viewModel.pageDidFailLoading
                )
            )

            if viewModel.isLoading {
                Loader()
            }
        }
        .background(DesignSystem.Color.bgBase.ignoresSafeArea())
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
    }
}
