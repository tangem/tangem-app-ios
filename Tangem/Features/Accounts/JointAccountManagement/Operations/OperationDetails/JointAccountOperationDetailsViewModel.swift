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
import TangemFoundation
import TangemLocalization
import TangemUI
import struct TangemUIUtils.AlertBinder

/// An operation of a joint account laid out as the transaction details it will become once it is sent.
///
/// - Note: Handed an operation already read out of its signed payload. The sheet does no parsing, no digest of its
///   own and no signing — that belongs to the domain layer over the Safe support in the SDK.
final class JointAccountOperationDetailsViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Published var alert: AlertBinder?
    @Published private(set) var isSigning = false

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

    @Published private(set) var answer: Answer

    private let canSign: Bool
    private let sign: () async throws -> Void
    private weak var coordinator: JointAccountOperationDetailsRoutable?
    private var signTask: Task<Void, Never>?

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
        canSign: Bool,
        coordinator: JointAccountOperationDetailsRoutable?,
        sign: @escaping () async throws -> Void
    ) {
        self.canSign = canSign
        self.sign = sign
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
        case .signOperation:
            signOperation()
        default:
            break
        }
    }
}

// MARK: - Signing

private extension JointAccountOperationDetailsViewModel {
    func signOperation() {
        guard signTask == nil else {
            return
        }

        isSigning = true
        signTask = runTask(in: self) { viewModel in
            do {
                try await viewModel.sign()
                await viewModel.finishSigning(with: nil)
            } catch {
                await viewModel.finishSigning(with: error)
            }
        }
    }

    @MainActor
    func finishSigning(with error: (any Error)?) {
        isSigning = false
        signTask = nil

        guard let error else {
            answer = .signed
            return
        }

        guard !error.isCancellationError else {
            return
        }

        JointAccountsLogger.error("Failed to sign a joint account operation", error: error)
        alert = AlertBuilder.makeAlertWithDefaultPrimaryButton(
            title: Localization.commonSomethingWentWrong,
            message: Localization.accountGenericErrorDialogMessage,
            buttonText: Localization.commonOk
        )
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

    var signBlock: TransactionDetailsBlock {
        .action(
            TransactionDetailsActionButtonViewData(
                title: signTitle,
                icon: isSignEnabled ? DesignSystem.Icons.LogoTangem.regular20 : nil,
                style: .default,
                action: .signOperation,
                isBusy: isSigning,
                isEnabled: isSignEnabled
            )
        )
    }

    var signTitle: String {
        switch answer {
        case .awaiting: Localization.commonSign
        case .signed: Localization.jointOperationSigned
        case .declined: Localization.jointOperationDeclined
        }
    }

    var isSignEnabled: Bool {
        guard canSign else {
            return false
        }

        switch answer {
        case .awaiting: return true
        case .signed, .declined: return false
        }
    }

    /// A member who declined is told the operation is not dead: the others can still reach the threshold without
    /// them, which is the whole point of a threshold below the member count.
    var footerBlock: TransactionDetailsBlock {
        switch answer {
        case .awaiting:
            .caption(Localization.jointOperationAutoSendsFooter(requiredSignaturesCount, membersCount))
        case .signed:
            .caption(Localization.jointOperationSignedFooter(requiredSignaturesCount, membersCount))
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
