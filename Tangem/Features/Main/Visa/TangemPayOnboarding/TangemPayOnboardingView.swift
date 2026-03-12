//
//  TangemPayOnboardingView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct TangemPayOnboardingView: View {
    @ObservedObject var viewModel: TangemPayOnboardingViewModel

    var body: some View {
        NavigationStack {
            Group {
                if let tangemPayOfferViewModel = viewModel.tangemPayOfferViewModel {
                    TangemPayOfferView(viewModel: tangemPayOfferViewModel)
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .onAppear(perform: viewModel.onAppear)
                }
            }
            .toolbar {
                NavigationToolbarButton.close(placement: .topBarTrailing, action: viewModel.closeOfferScreen)
            }
        }
    }
}
