//
//  AddCustomTokenNetworkSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization

struct AddCustomTokenNetworkSelectorView: View {
    let viewModel: AddCustomTokenNetworksListViewModel

    var body: some View {
        AddCustomTokenNetworksListView(viewModel: viewModel)
            .navigationBarTitle(Text(Localization.customTokenNetworkSelectorTitle), displayMode: .inline)
    }
}

#Preview {
    AddCustomTokenNetworkSelectorView(
        viewModel: AddCustomTokenNetworksListViewModel(
            selectedBlockchainNetworkId: SupportedBlockchains.all.filter(\.isTestnet).first!.networkId,
            blockchains: SupportedBlockchains.all.filter(\.isTestnet)
        )
    )
}
