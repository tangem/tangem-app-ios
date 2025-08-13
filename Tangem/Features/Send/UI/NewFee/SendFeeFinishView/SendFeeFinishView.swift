//
//  SendFeeFinishView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization
import TangemAccessibilityIdentifiers

struct SendFeeFinishView: View {
    @ObservedObject var viewModel: SendFeeFinishViewModel

    var body: some View {
        GroupedSection(viewModel.selectedFeeRowViewModel) { feeRowViewModel in
            FeeRowView(viewModel: feeRowViewModel)
                .accessibilityIdentifier(feeRowViewModel.option.accessibilityIdentifier)
        } header: {
            DefaultHeaderView(Localization.commonNetworkFeeTitle)
                .padding(.top, 12)
        }
        .backgroundColor(Colors.Background.action)
        .accessibilityIdentifier(SendAccessibilityIdentifiers.networkFeeBlock)
    }
}
