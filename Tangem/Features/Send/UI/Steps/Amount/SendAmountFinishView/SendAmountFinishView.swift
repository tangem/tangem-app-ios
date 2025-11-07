//
//  SendAmountFinishView.swift
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

struct SendAmountFinishView: View {
    @ObservedObject var viewModel: SendAmountFinishViewModel

    var body: some View {
        switch viewModel.viewType {
        case .one(let large):
            SendAmountFinishLargeAmountView(viewModel: large)
        case .double(let source, let destination, let provider):
            // Spacing between views will be added in `SendFinishView`

            SendAmountFinishSmallAmountView(viewModel: source)

            SendAmountFinishSmallAmountView(viewModel: destination)

            SendSwapProviderFinishView(viewModel: provider)
        }
    }
}
