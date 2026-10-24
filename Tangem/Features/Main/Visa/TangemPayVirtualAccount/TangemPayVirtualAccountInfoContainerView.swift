//
//  TangemPayVirtualAccountInfoContainerView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct TangemPayVirtualAccountInfoContainerView: View {
    @ObservedObject var viewModel: TangemPayVirtualAccountInfoSheetViewModel

    var body: some View {
        if FeatureProvider.isAvailable(.tangemPayOnrampV2) {
            TangemPayVirtualAccountOnboardingView(viewModel: viewModel)
        } else {
            TangemPayVirtualAccountInfoSheetView(viewModel: viewModel)
        }
    }
}
