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
import TangemAccessibilityIdentifiers

struct SendAmountFinishView: View {
    @ObservedObject var viewModel: SendAmountFinishViewModel

    var body: some View {
        // Spacing between views will be added in `SendFinishView`

        switch viewModel.viewType {
        case .none:
            EmptyView()

        case .one(let large):
            SendAmountFinishLargeAmountView(viewModel: large)

        case .double(let source, let destination):
            SendAmountFinishSmallAmountView(viewModel: source)
                .accessibilityIdentifier(SendAccessibilityIdentifiers.finishSourceAmountBlock)

            SendAmountFinishSmallAmountView(viewModel: destination)
                .accessibilityIdentifier(SendAccessibilityIdentifiers.finishDestinationAmountBlock)

        case .triple(let source, let destination, let provider):
            SendAmountFinishSmallAmountView(viewModel: source)
                .accessibilityIdentifier(SendAccessibilityIdentifiers.finishSourceAmountBlock)

            SendAmountFinishSmallAmountView(viewModel: destination)
                .accessibilityIdentifier(SendAccessibilityIdentifiers.finishDestinationAmountBlock)

            SendSwapProviderFinishView(viewModel: provider)
                .accessibilityIdentifier(SendAccessibilityIdentifiers.finishProviderBlock)
        }
    }
}
