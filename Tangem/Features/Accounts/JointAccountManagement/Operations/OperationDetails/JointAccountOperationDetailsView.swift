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

#Preview("Failed") {
    JointAccountOperationDetailsView(viewModel: .preview(answer: .signed, status: .failed(at: Date())))
        .frame(maxHeight: .infinity, alignment: .bottom)
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}

#Preview("Cancelled") {
    JointAccountOperationDetailsView(viewModel: .preview(answer: .signed, status: .cancelled(at: Date())))
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
            recipientState: .init(
                owner: .unresolved(
                    short: "33Bd321fS2…dSga21412B",
                    fullAddress: "33Bd321fS2p2o8Bk7mQwXeATkLQ3B36Yv2p210xxdSga21412B",
                    blockiesImage: nil
                ),
                canAddToContacts: true
            ),
            blockchain: .ethereum(testnet: false),
            networkFee: "~0.00056 ETH",
            signingActionButtonType: .requiredNFCInteraction,
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
                canReject: true,
                isInitiator: false,
                status: status
            ),
            contentPublisher: .empty,
            addressBookWallet: AddressBookWallet(
                wallet: UserWalletModelMock().userWalletInfo,
                addressBookManager: NoopAddressBookManager()
            ),
            addressBookAnalyticsLogger: CommonAddressBookAnalyticsLogger(),
            recipientStatePublisher: .empty,
            poller: JointAccountPendingOperationPollerMock(),
            coordinator: nil,
            sign: {},
            reject: {}
        )
    }
}
