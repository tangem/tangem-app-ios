//
//  TransferInputView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct TransferInputView: View {
    @ObservedObject var viewModel: TransferInputViewModel

    var body: some View {
        TransferInputContentView(
            amountFieldViewModel: viewModel.amountFieldViewModel,
            state: viewModel.contentState,
            action: viewModel.handle
        )
        .background { DesignSystem.Color.bgPrimary.ignoresSafeArea() }
        .topNavigation(
            title: viewModel.title,
            subtitle: viewModel.stepSubtitle,
            onClose: viewModel.onCloseTap
        )
        .sheet(isPresented: $viewModel.isTokenModalPresented) {
            TransferInputTokenModalView(
                items: viewModel.tokenItems,
                selection: viewModel.tokenSelectionBinding,
                onClose: { viewModel.isTokenModalPresented = false }
            )
            .presentationDetents(idealHeight: Constants.tokenModalIdealHeight)
        }
        .sheet(isPresented: $viewModel.isRailModalPresented) {
            TransferInputRailModalView(
                items: viewModel.railItems,
                selection: viewModel.railSelectionBinding,
                onClose: { viewModel.isRailModalPresented = false }
            )
            .presentationDetents(idealHeight: Constants.railModalIdealHeight)
        }
    }
}

// MARK: - Constants

private extension TransferInputView {
    enum Constants {
        static let tokenModalIdealHeight: CGFloat = 480
        static let railModalIdealHeight: CGFloat = 240
    }
}
