//
//  TransferTypeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct TransferTypeView: View {
    @StateObject private var viewModel: TransferTypeViewModel

    init(viewModel: @autoclosure @escaping () -> TransferTypeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        TransferTypeContentView(
            state: viewModel.contentState,
            action: viewModel.handle
        )
        .background { DesignSystem.Color.bgPrimary.ignoresSafeArea() }
        .topNavigation(
            title: viewModel.title,
            subtitle: viewModel.stepSubtitle,
            onClose: viewModel.onCloseTap
        )
    }
}
