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
        TangemPayVirtualAccountOnboardingView(viewModel: viewModel)
    }
}
