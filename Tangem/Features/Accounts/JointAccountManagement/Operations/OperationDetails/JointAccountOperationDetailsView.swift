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

    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .details:
            TransactionDetailsContentView(
                header: viewModel.header,
                blocks: viewModel.blocks,
                animatesBlockChanges: true,
                onAction: viewModel.handleViewAction
            )
        case .signers(let signersViewModel):
            JointAccountSignersView(viewModel: signersViewModel)
        }
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

#Preview("Sending to the network") {
    JointAccountOperationDetailsView(viewModel: .preview(answer: .signed, status: .sending))
        .frame(maxHeight: .infinity, alignment: .bottom)
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}

#Preview("Sent to the network") {
    JointAccountOperationDetailsView(viewModel: .preview(answer: .signed, status: .sent(at: Date())))
        .frame(maxHeight: .infinity, alignment: .bottom)
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}

private extension JointAccountOperationDetailsViewModel {
    static func preview(answer: Answer, status: Status = .awaitingSignatures) -> JointAccountOperationDetailsViewModel {
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
            recipient: "33Bd321fS2p2o8Bk7mQwXeATkLQ3B36Yv2p210xxdSga21412B",
            recipientBlockiesImage: nil,
            networkFee: "~0.00056 ETH",
            signingActionButtonType: .cardTap,
            content: .init(
                collectedSignaturesCount: 1,
                requiredSignaturesCount: 3,
                membersCount: 5,
                signers: [
                    .init(
                        id: "0x1",
                        icon: .init(letter: "I", color: CompositeIconColorPalette.color(for: .azure)),
                        name: "Isaac",
                        answer: .created(at: "15:34")
                    ),
                    .init(
                        id: "0x2",
                        icon: .init(letter: "O", color: CompositeIconColorPalette.color(for: .mexicanPink)),
                        name: "Olivia",
                        answer: .waiting
                    ),
                ],
                answer: answer,
                canSign: true,
                status: status
            ),
            contentPublisher: .empty,
            pendingOperationsProvider: nil,
            coordinator: nil,
            sign: {}
        )
    }
}
