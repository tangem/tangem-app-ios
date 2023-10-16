//
//  ManageTokensNetworkSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct ManageTokensNetworkSelectorView: View {
    @ObservedObject var viewModel: ManageTokensNetworkSelectorViewModel

    var body: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.selectorItems) {
                ManageTokensNetworkSelectorItemView(viewModel: $0)
            }
        }
    }
}
