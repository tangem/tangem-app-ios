//
//  TangemPayPlasticReissuePopupView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct TangemPayPlasticReissuePopupView: View {
    @ObservedObject var viewModel: TangemPayPlasticReissueSheetViewModel

    var body: some View {
        TangemPayPopupView(viewModel: viewModel) {
            TangemPayOrderCardInfoRowsView(rows: viewModel.infoRows)
                .padding(.horizontal, 8)
                .padding(.top, 16)
        }
    }
}
