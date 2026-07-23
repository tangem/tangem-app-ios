//
//  TangemPayIssueAdditionalCardCostPopupView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct TangemPayIssueAdditionalCardCostPopupView: View {
    @ObservedObject var viewModel: TangemPayIssueAdditionalCardCostPopupViewModel

    var body: some View {
        TangemPayFeePopupView(viewModel: viewModel)
    }
}
