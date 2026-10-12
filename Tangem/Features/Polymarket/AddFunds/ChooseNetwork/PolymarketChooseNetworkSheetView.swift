//
//  PolymarketChooseNetworkSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemPolymarketUI

struct PolymarketChooseNetworkSheetView: View {
    @ObservedObject var viewModel: PolymarketChooseNetworkSheetViewModel

    var body: some View {
        PolymarketChooseNetworkView(rows: viewModel.rows, onClose: viewModel.close)
    }
}
