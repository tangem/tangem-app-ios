//
//  SupportedBlockchainsPreferencesView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct SupportedBlockchainsPreferencesView: View {
    @ObservedObject var viewModel: SupportedBlockchainsPreferencesViewModel

    var body: some View {
        GroupedScrollView {
            GroupedSection(viewModel.blockchainViewModels) {
                DefaultToggleRowView(viewModel: $0)
            }
        }
        .interContentPadding(8)
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .navigationTitle(Text("Supported blockchains"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
