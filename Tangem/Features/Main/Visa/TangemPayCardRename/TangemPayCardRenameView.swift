//
//  TangemPayCardRenameView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct TangemPayCardRenameView: View {
    @ObservedObject var viewModel: TangemPayCardRenameViewModel

    var body: some View {
        TangemPayCardDetailsView(viewModel: viewModel.renameCardDetailsViewModel)
            .alert(item: $viewModel.alert) { $0.alert }
    }
}
