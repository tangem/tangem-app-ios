//
//  SendNewAmountFinishView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemUI
import TangemAssets
import TangemLocalization

struct SendNewAmountFinishView: View {
    @ObservedObject var viewModel: SendNewAmountFinishViewModel

    var body: some View {
        switch viewModel.viewType {
        case .one(let large):
            SendNewAmountFinishLargeAmountView(viewModel: large)
        case .double(let source, let destination, let provider):
            // Spacing between views will be added in `SendNewFinishView`

            SendNewAmountFinishSmallAmountView(viewModel: source)

            SendNewAmountFinishSmallAmountView(viewModel: destination)

            SendSwapProviderFinishView(viewModel: provider)
        }
    }
}
