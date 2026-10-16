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
                if viewModel.regionUnavailable {
                    TangemPayRegionUnavailableView(onGotIt: viewModel.closeOfferScreen)
                } else if let tangemPayOfferViewModel = viewModel.tangemPayOfferViewModel {
                    Group {
                        switch viewModel.screenVersion {
                        case .v2:
                            TangemPayOfferViewV2(viewModel: tangemPayOfferViewModel)
                        case .v1:
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
                if viewModel.screenVersion == .v2, let tangemPayOfferViewModel = viewModel.tangemPayOfferViewModel {
                    ToolbarItem(placement: .topBarTrailing) {
                        SwiftUI.Button(action: tangemPayOfferViewModel.termsFeesAndLimits) {
                            Assets.Visa.tangemPayOnboardingNewDoc.image
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(DesignSystem.Color.iconPrimary)
                        }
                    }

                    if #available(iOS 26.0, *) {
                        ToolbarSpacer(.fixed, placement: .topBarTrailing)
                    }
                }

                if !viewModel.regionUnavailable {
                    NavigationToolbarButton.close(placement: .topBarTrailing, action: viewModel.closeOfferScreen)
                }
            }
        }
    }
}
