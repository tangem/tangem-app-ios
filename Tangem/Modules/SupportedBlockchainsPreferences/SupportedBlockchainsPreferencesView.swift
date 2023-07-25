//
//  SupportedBlockchainsPreferencesView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SupportedBlockchainsPreferencesView: View {
    @ObservedObject var viewModel: SupportedBlockchainsPreferencesViewModel

    var body: some View {
        GroupedScrollView {
            GroupedSection(viewModel.blockchainViewModels) {
                DefaultToggleRowView(viewModel: $0)
            }
        }
        .navigationTitle(Text("Supported blockchains"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
