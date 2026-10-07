//
//  TangemPayVirtualAccountDetailsView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemLocalization

struct TangemPayVirtualAccountDetailsView: View {
    @ObservedObject var viewModel: TangemPayVirtualAccountDetailsViewModel

    var body: some View {
        NavigationStack {
            TangemPayVirtualAccountDetailsContentView(state: viewModel.contentState, action: handle)
                .topNavigation(title: Localization.tangempayVaAccountDetails, onClose: viewModel.close)
        }
    }
}

// MARK: - Actions

private extension TangemPayVirtualAccountDetailsView {
    func handle(_ action: TangemPayVirtualAccountDetailsContentView.Action) {
        switch action {
        case .copy(let row):
            viewModel.copy(row)
        case .reloadFees:
            viewModel.reloadFees()
        case .share:
            viewModel.share()
        }
    }
}
