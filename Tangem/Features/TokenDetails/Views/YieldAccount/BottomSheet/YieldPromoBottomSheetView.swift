//
//  YieldPromoBottomSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct YieldPromoBottomSheetView: View {
    @ObservedObject var viewModel: YieldPromoBottomSheetViewModel

    var body: some View {
        switch viewModel.state {
        case .feePolicy:
            FeePolicyView(currentFee: "1.45", maximumFee: "1.6", backAction: viewModel.onCloseTapAction)

        case .startYearing:
            Text("Start Yearning")
        }
    }
}

#Preview {
    YieldPromoBottomSheetView(viewModel: .init(state: .feePolicy))
}
