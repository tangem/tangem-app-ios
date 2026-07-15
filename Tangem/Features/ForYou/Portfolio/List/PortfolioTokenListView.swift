//
//  PortfolioTokenListView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct PortfolioTokenListView: View {
    @ObservedObject var viewModel: PortfolioTokenListViewModel

    var body: some View {
        VStack(spacing: 8) {
            ForEach(viewModel.items) { item in
                PortfolioTokenItemView(
                    item: item,
                    onAssetTap: viewModel.toggleAsset
                )
            }
        }
    }
}
