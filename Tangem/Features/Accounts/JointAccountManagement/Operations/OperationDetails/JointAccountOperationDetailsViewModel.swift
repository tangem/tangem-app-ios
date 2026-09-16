//
//  JointAccountOperationDetailsViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import TangemAssets
import TangemLocalization
import TangemUI

/// An operation of a joint account laid out as the transaction details it will become once it is sent.
///
/// - Note: Handed an operation already read out of its signed payload. The sheet does no parsing, no digest of its
///   own and no signing — that belongs to the domain layer over the Safe support in the SDK.
final class JointAccountOperationDetailsViewModel: ObservableObject, FloatingSheetContentViewModel {
    let tokenIconInfo: TokenIconInfo
    /// Written out for display, and taken from the payload's own `value` rather than from a field on the response.
    let cryptoAmount: String
    let fiatAmount: String
    /// Already shortened, taken from the payload's own `to`.
    let recipient: String
    /// Rendered ahead of time rather than in the view body: generating blockies is not free, and the sheet has no
    /// reason to redo it on every recomputation.
    let recipientBlockiesImage: UIImage?
    let networkFee: String
    /// Includes the initiator's signature, so it is never zero for an operation that exists.
    let collectedSignaturesCount: Int
    /// How many of the members have to sign for the operation to go through.
    let requiredSignaturesCount: Int
    /// Everyone on the account. Kept apart from the threshold because the copy needs both: the progress line
    /// counts the answers against the roster, while the footer names the threshold against it.
    let membersCount: Int
    let answer: Answer

    private weak var coordinator: JointAccountOperationDetailsRoutable?

    init(
        tokenIconInfo: TokenIconInfo,
        cryptoAmount: String,
        fiatAmount: String,
        recipient: String,
        recipientBlockiesImage: UIImage?,
        networkFee: String,
        collectedSignaturesCount: Int,
        requiredSignaturesCount: Int,
        membersCount: Int,
        answer: Answer,
        coordinator: JointAccountOperationDetailsRoutable?
    ) {
        self.tokenIconInfo = tokenIconInfo
        self.cryptoAmount = cryptoAmount
        self.fiatAmount = fiatAmount
        self.recipient = recipient
        self.recipientBlockiesImage = recipientBlockiesImage
        self.networkFee = networkFee
        self.collectedSignaturesCount = collectedSignaturesCount
        self.requiredSignaturesCount = requiredSignaturesCount
        self.membersCount = membersCount
        self.answer = answer
        self.coordinator = coordinator
    }

    /// Neutral icon and title by design: the warning-coloured line under the title is what says the operation is
    /// still waiting, and repeating that in the title would say it twice.
    var header: TransactionDetailsHeaderViewData {
        TransactionDetailsHeaderViewData(
            title: Localization.commonSend,
            titleStyle: .neutral,
            date: Localization.transactionHistoryPending,
            subtitleStyle: .warning,
            operationIcon: TransactionViewIconViewData(type: .transfer, status: .confirmed, isOutgoing: true),
            iconGlyph: nil,
            menuSections: []
        )
    }

    var blocks: [TransactionDetailsBlock] {
        [
            amountBlock,
            recipientBlock,
            signaturesBlock,
            networkFeeBlock,
            signBlock,
            footerBlock,
        ].compactMap { $0 }
    }

    func handleViewAction(_ action: TransactionDetailsViewModel.ViewAction) {
        switch action {
        case .close:
            coordinator?.closeOperationDetails()
        case .openSigners:
            coordinator?.openSigners()
        case .signOperation:
            coordinator?.signOperation()
        default:
            break
        }
    }
}

// MARK: - Blocks

private extension JointAccountOperationDetailsViewModel {
    var amountBlock: TransactionDetailsBlock {
        .tokens(
            TransactionDetailsTokensViewData(
                icon: .token(tokenIconInfo),
                caption: nil,
                amountText: cryptoAmount,
                fiatText: fiatAmount,
                isAmountStrikethrough: false
            )
        )
    }

    var recipientBlock: TransactionDetailsBlock {
        .counterparty(
            TransactionDetailsAddressViewData(
                label: Localization.sendRecipient,
                actor: .address(
                    short: recipient,
                    blockiesImage: AddressBlockiesIconViewData(image: recipientBlockiesImage)
                ),
                copyAction: nil
            )
        )
    }

    var signaturesBlock: TransactionDetailsBlock {
        .signatures(
            TransactionDetailsSignaturesViewData(
                title: Localization.jointOperationSignaturesProgress(collectedSignaturesCount, membersCount),
                collectedCount: collectedSignaturesCount,
                membersCount: membersCount
            )
        )
    }

    var networkFeeBlock: TransactionDetailsBlock {
        .info(
            TransactionDetailsInfoSectionViewData(
                rows: [
                    TransactionDetailsInfoSectionViewData.Row(
                        id: Constants.networkFeeRowID,
                        title: Localization.commonNetworkFeeTitle,
                        content: .text(networkFee)
                    ),
                ]
            )
        )
    }

    /// Offered only while this member still has an answer to give; the Tangem mark on it says the signature comes
    /// from the wallet rather than from a tap.
    var signBlock: TransactionDetailsBlock? {
        guard isSignAvailable else {
            return nil
        }

        return .action(
            TransactionDetailsActionButtonViewData(
                title: Localization.commonSign,
                icon: DesignSystem.Icons.LogoTangem.regular20,
                style: .default,
                action: .signOperation
            )
        )
    }

    var isSignAvailable: Bool {
        switch answer {
        case .awaiting: true
        case .signed, .declined: false
        }
    }

    /// A member who declined is told the operation is not dead: the others can still reach the threshold without
    /// them, which is the whole point of a threshold below the member count.
    var footerBlock: TransactionDetailsBlock {
        switch answer {
        case .awaiting, .signed:
            .caption(Localization.jointOperationAutoSendsFooter(requiredSignaturesCount, membersCount))
        case .declined:
            .caption(Localization.jointOperationDeclinedFooter(requiredSignaturesCount, membersCount))
        }
    }
}

// MARK: - Constants

private extension JointAccountOperationDetailsViewModel {
    enum Constants {
        static let networkFeeRowID = "joint_operation_network_fee"
    }
}

// MARK: - Auxiliary types

extension JointAccountOperationDetailsViewModel {
    /// What this member has already done about the operation.
    enum Answer {
        case awaiting
        case signed
        case declined
    }
}
