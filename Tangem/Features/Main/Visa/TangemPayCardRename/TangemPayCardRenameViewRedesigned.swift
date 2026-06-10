//
//  TangemPayCardRenameViewRedesigned.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct TangemPayCardRenameViewRedesigned: View {
    @ObservedObject var viewModel: TangemPayCardRenameViewModel

    var body: some View {
        TangemPayCardDetailsViewRedesigned(viewModel: viewModel.renameCardDetailsViewModel)
    }
}
