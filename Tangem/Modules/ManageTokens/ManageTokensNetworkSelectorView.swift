//
//  ManageTokensNetworkSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk

struct ManageTokensNetworkSelectorView: View {
    let blockchain: Blockchain

    var body: some View {
        HStack {
            Text("Hello, World!")

            NetworkIcon(imageName: blockchain.iconNameFilled, isActive: false, isMainIndicatorVisible: false)
        }
    }
}

struct ManageTokensNetworkSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        ManageTokensNetworkSelectorView(blockchain: .ethereum(testnet: false))
    }
}
