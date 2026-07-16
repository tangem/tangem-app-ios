//
//  TangemPayReissuePopupView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct TangemPayReissuePopupView: View {
    @ObservedObject var viewModel: TangemPayReissueSheetViewModel

    var body: some View {
        TangemPayFeePopupView(viewModel: viewModel)
    }
}
