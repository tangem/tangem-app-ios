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

struct AddCustomTokenNetworkSelectorView_Preview: PreviewProvider {
    static let blockchains: Array = SupportedBlockchains.all.filter(\.isTestnet)

    static let viewModel = AddCustomTokenNetworksListViewModel(
        selectedBlockchainNetworkId: blockchains.first!.networkId,
        blockchains: blockchains
    )

    static var previews: some View {
        AddCustomTokenNetworkSelectorView(viewModel: viewModel)
    }
}
