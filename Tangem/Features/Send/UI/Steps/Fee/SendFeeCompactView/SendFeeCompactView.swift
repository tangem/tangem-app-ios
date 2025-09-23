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
    let type: SendCompactViewEditableType

    var body: some View {
        GroupedSection(viewModel.selectedFeeRowViewModel) { feeRowViewModel in
            FeeRowView(viewModel: feeRowViewModel)
                .accessibilityIdentifier(feeRowViewModel.option.accessibilityIdentifier)
        } header: {
            DefaultHeaderView(Localization.commonNetworkFeeTitle)
                .padding(.top, 12)
        }
        .backgroundColor(Colors.Background.action)
        .readGeometry(\.size, bindTo: $viewModel.viewSize)
        .contentShape(Rectangle())
        .allowsHitTesting(viewModel.canEditFee)
        .onTapGesture {
            if case .enabled(.some(let action)) = type {
                action()
            }
        }
        .accessibilityIdentifier(SendAccessibilityIdentifiers.networkFeeBlock)
    }
}
