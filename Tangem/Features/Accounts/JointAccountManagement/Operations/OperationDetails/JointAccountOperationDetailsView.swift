//
//  JointAccountOperationDetailsView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

/// What one operation of a joint account will actually do, for the member deciding whether to sign it.
///
/// Drawn with the transaction details content rather than a layout of its own: an operation is the transaction it
/// will become once enough members sign, and it is worth reading the same way before and after it is sent.
struct JointAccountOperationDetailsView: View {
    @ObservedObject var viewModel: JointAccountOperationDetailsViewModel

    var body: some View {
        TransactionDetailsContentView(
            header: viewModel.header,
            blocks: viewModel.blocks,
            onAction: viewModel.handleViewAction
        )
    }
}

// MARK: - Previews

#Preview("Awaiting this member") {
    JointAccountOperationDetailsView(viewModel: .preview(answer: .awaiting))
        .frame(maxHeight: .infinity, alignment: .bottom)
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}

#Preview("Declined by this member") {
    JointAccountOperationDetailsView(viewModel: .preview(answer: .declined))
        .frame(maxHeight: .infinity, alignment: .bottom)
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}

private extension JointAccountOperationDetailsViewModel {
    static func preview(answer: Answer) -> JointAccountOperationDetailsViewModel {
        JointAccountOperationDetailsViewModel(
            tokenIconInfo: TokenIconInfo(
                name: "Ethereum",
                blockchainIconAsset: nil,
                imageURL: nil,
                isCustom: false,
                customTokenColor: nil
            ),
            cryptoAmount: "–0.3212 ETH",
            fiatAmount: "$591.08",
            recipient: "33Bd321fS…0xxdSga21412B",
            recipientBlockiesImage: nil,
            networkFee: "~0.00056 ETH",
            collectedSignaturesCount: 1,
            requiredSignaturesCount: 3,
            membersCount: 5,
            answer: answer,
            coordinator: nil
        )
    }
}
