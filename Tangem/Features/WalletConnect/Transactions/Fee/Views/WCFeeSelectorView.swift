//
//  FeeSelectorContentView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemLocalization
import TangemAssets

struct WCFeeSelectorView: View {
    @ObservedObject var viewModel: FeeSelectorContentViewModel

    var body: some View {
        ScrollView {
            SelectableSection(viewModel.feesRowData) { data in
                FeeSelectorContentRowView(viewModel: data, isSelected: viewModel.isSelected(data.feeOption).asBinding)
            }
            // Should start when title starts (14 + 36 + 12)
            .separatorPadding(.init(leading: 62, trailing: 14))
            .padding(.horizontal, 14)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onAppear(perform: viewModel.onAppear)
    }
}
