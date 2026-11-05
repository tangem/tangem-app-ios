//
//  JointAccountOperationDetailsView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemUI

/// What one operation of a joint account will actually do, for the member deciding whether to sign it.
///
/// Drawn with the transaction details content rather than a layout of its own: an operation is the transaction it
/// will become once enough members sign, and it is worth reading the same way before and after it is sent.
struct JointAccountOperationDetailsView: View {
    @ObservedObject var viewModel: JointAccountOperationDetailsViewModel

    var body: some View {
        content
            .onAppear(perform: viewModel.onAppear)
            .onDisappear(perform: viewModel.onDisappear)
    }

    private var content: some View {
        ZStack(alignment: .top) {
            switch viewModel.viewState {
            case .details:
                TransactionDetailsContentView(
                    header: viewModel.header,
                    blocks: viewModel.blocks,
                    animatesBlockChanges: true,
                    onAction: viewModel.handleViewAction
                )
                .transition(.transactionDetailsContent)
            case .signers(let signersViewModel):
                JointAccountSignersView(viewModel: signersViewModel)
                    .transition(.transactionDetailsOverlay)
            }
        }
        .animation(.contentFrameUpdate, value: isShowingSigners)
    }

    private var isShowingSigners: Bool {
        if case .signers = viewModel.viewState {
            return true
        }

        return false
    }
}

// MARK: - Content transition

private extension Animation {
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
}
