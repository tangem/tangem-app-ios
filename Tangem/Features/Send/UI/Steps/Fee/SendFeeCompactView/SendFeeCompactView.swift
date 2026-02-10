//
//  SendFeeCompactView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendFeeCompactView: View {
    @ObservedObject var viewModel: SendFeeCompactViewModel
    let tapAction: (() -> Void)?

    var body: some View {
        if viewModel.feeCompactViewIsVisible {
            FeeCompactView(viewModel: viewModel.feeCompactViewModel, tapAction: tapAction)
        }
    }
}
