//
//  ExpressApproveFlowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct ExpressApproveFlowView: View {
    @ObservedObject private var viewModel: ExpressApproveFlowViewModel

    init(viewModel: ExpressApproveFlowViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        content
            .background(Colors.Background.tertiary)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .approve(let approveViewModel):
            ExpressApproveView(viewModel: approveViewModel)
        }
    }
}
