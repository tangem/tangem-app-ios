//
//  MarketsTokenDetailsPortfolioBannerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsTokenDetailsPortfolioBannerView: View {
    @ObservedObject var viewModel: MarketsTokenDetailsPortfolioBannerViewModel

    var body: some View {
        switch viewModel.totalFiatBalance {
        case .loading:
            Text("loading")
        case .empty:
            Text("empty")
        case .loaded(let decimal):
            Text("loaded \(decimal)")
        }
    }
}
