//
//  TangemPayOnboardingView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct TangemPayOnboardingView: View {
    @ObservedObject var viewModel: TangemPayOnboardingViewModel

    var body: some View {
        NavigationStack {
            Group {
                if let tangemPayOfferViewModel = viewModel.tangemPayOfferViewModel {
                    Group {
                        if viewModel.showNewOnboarding {
                            TangemPayOfferViewV2(viewModel: tangemPayOfferViewModel)
                        } else {
                            TangemPayOfferView(viewModel: tangemPayOfferViewModel)
                        }
                    }
                    .onAppear(perform: viewModel.onOfferAppear)
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .onAppear(perform: viewModel.onAppear)
                }
            }
            .toolbar {
                if viewModel.showNewOnboarding, let tangemPayOfferViewModel = viewModel.tangemPayOfferViewModel {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: tangemPayOfferViewModel.termsFeesAndLimits) {
                            Assets.Visa.tangemPayOnboardingNewDoc.image
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(Color.Tangem.Graphic.Neutral.primary)
                        }
                    }

                    if #available(iOS 26.0, *) {
                        ToolbarSpacer(.fixed, placement: .topBarTrailing)
                    }
                }

                NavigationToolbarButton.close(placement: .topBarTrailing, action: viewModel.closeOfferScreen)
            }
        }
    }
}
