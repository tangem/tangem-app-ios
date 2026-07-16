//
//  TangemPayCloseCardSheetView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct TangemPayCloseCardSheetView: View {
    @ObservedObject var viewModel: TangemPayCloseCardSheetViewModel

    var body: some View {
        TangemPayPopupView(viewModel: viewModel)
    }
}
