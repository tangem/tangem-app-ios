//
//  SendFeeCompactView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUIUtils
import TangemUI
import TangemAccessibilityIdentifiers

struct SendFeeCompactView: View {
    @ObservedObject var viewModel: SendFeeCompactViewModel

    var body: some View {
        GroupedSection(viewModel.selectedFeeRowViewModel) { feeRowViewModel in
            FeeRowView(viewModel: feeRowViewModel)
                .accessibilityIdentifier(feeRowViewModel.option.accessibilityIdentifier)
        } header: {
            DefaultHeaderView(Localization.commonNetworkFeeTitle)
                .padding(.top, 12)
        }
        .backgroundColor(Colors.Background.action)
        .contentShape(Rectangle())
        .allowsHitTesting(viewModel.canEditFee)
        .accessibilityIdentifier(SendAccessibilityIdentifiers.networkFeeBlock)
    }
}
