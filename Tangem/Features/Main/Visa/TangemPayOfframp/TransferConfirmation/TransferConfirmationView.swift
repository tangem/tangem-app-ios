//
//  TransferConfirmationView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct TransferConfirmationView: View {
    @StateObject private var viewModel: TransferConfirmationViewModel

    init(viewModel: @autoclosure @escaping () -> TransferConfirmationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        TransferConfirmationContentView(
            state: viewModel.contentState,
            action: viewModel.handle
        )
        .background { DesignSystem.Color.bgPrimary.ignoresSafeArea() }
        .topNavigation(
            title: viewModel.title,
            leading: viewModel.isSending ? .none : .automatic,
            onClose: viewModel.onCloseTap
        )
        .onAppear(perform: viewModel.refresh)
    }
}
