//
//  JointAccountOperationDetailsViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import UIKit
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemUI

/// An operation of a joint account laid out as the transaction details it will become once it is sent.
///
/// - Note: Handed an operation already read out of its signed payload. The sheet does no parsing, no digest of its
///   own and no signing — that belongs to the domain layer over the Safe support in the SDK.
final class JointAccountOperationDetailsViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Published private(set) var isSigning = false
    @Published private(set) var viewState: ViewState = .details
    @Published private(set) var content: Content
    @Published private(set) var answer: Answer

    private let alertPresenter: AlertPresenter

    let tokenIconInfo: TokenIconInfo
    /// Written out for display, and taken from the payload's own `value` rather than from a field on the response.
    let cryptoAmount: String
    let fiatAmount: String
    /// Taken from the payload's own `to`.
    let recipient: String
    /// Rendered ahead of time rather than in the view body: generating blockies is not free, and the sheet has no
    /// reason to redo it on every recomputation.
    let recipientBlockiesImage: UIImage?
    let networkFee: String

    private let hasNFCInteraction: Bool
    private let sign: () async throws -> Void
    private let pendingOperationsProvider: (any JointAccountPendingOperationsProvider)?
    private weak var coordinator: JointAccountOperationDetailsRoutable?
    private var signTask: Task<Void, Never>?
    private var isClosing = false
    private var updatesSubscription: AnyCancellable?
    private var frequentUpdatesSubscription: AnyCancellable?

    init(
        tokenIconInfo: TokenIconInfo,
        cryptoAmount: String,
        fiatAmount: String,
        recipient: String,
        recipientBlockiesImage: UIImage?,
        networkFee: String,
        hasNFCInteraction: Bool,
        content: Content,
        contentPublisher: AnyPublisher<Content, Never>,
        pendingOperationsProvider: (any JointAccountPendingOperationsProvider)?,
        coordinator: JointAccountOperationDetailsRoutable?,
        alertPresenter: AlertPresenter = InjectedValues[\.alertPresenter],
        sign: @escaping () async throws -> Void
    ) {
        self.tokenIconInfo = tokenIconInfo
        self.cryptoAmount = cryptoAmount
        self.fiatAmount = fiatAmount
        self.recipient = recipient
        self.recipientBlockiesImage = recipientBlockiesImage
        self.networkFee = networkFee
        self.hasNFCInteraction = hasNFCInteraction
        self.content = content
        answer = content.answer
        self.sign = sign
        self.pendingOperationsProvider = pendingOperationsProvider
        self.coordinator = coordinator
        self.alertPresenter = alertPresenter

        bind(contentPublisher: contentPublisher)
    }

    /// While signatures are collected the icon and title stay neutral by design: the warning-coloured line under the
    /// title is what says the operation is still waiting, and repeating that in the title would say it twice.
    var header: TransactionDetailsHeaderViewData {
        TransactionDetailsHeaderViewData(
            title: headerTitle,
            titleStyle: content.status == .sending ? .active : .neutral,
            date: headerSubtitle,
            subtitleStyle: content.status == .awaitingSignatures ? .warning : .secondary,
            operationIcon: TransactionViewIconViewData(
                type: .transfer,
                status: content.status == .sending ? .inProgress : .confirmed,
                isOutgoing: true
            ),
            iconGlyph: nil,
            menuSections: [
                .init(
                    id: Constants.addressMenuSectionID,
                    actions: [TransactionDetailsMenuFactory.copyAddressAction(for: recipient)]
                ),
            ]
        )
    }

    private var headerTitle: String {
        switch content.status {
        case .awaitingSignatures: Localization.commonSend
        case .sending: Localization.commonSending
        case .sent: Localization.commonSent
        }
    }

    private var headerSubtitle: String {
        switch content.status {
        case .awaitingSignatures: Localization.transactionHistoryPending
        case .sending: Localization.jointOperationSendingToNetwork
        case .sent(let date): TransactionDetailsFactory.headerDateFormatter.string(from: date)
        }
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

    func onAppear() {
        frequentUpdatesSubscription = pendingOperationsProvider?.requestFrequentUpdates()
    }

    func onDisappear() {
        frequentUpdatesSubscription = nil
    }

    func handleViewAction(_ action: TransactionDetailsViewModel.ViewAction) {
        switch action {
        case .close:
            close()
        case .signOperation:
            signOperation()
        case .openSigners:
            openSigners()
        case .copy(let value, let toast, _):
            copy(value, toast: toast)
        default:
            break
        }
    }
}

// MARK: - Updates

private extension JointAccountOperationDetailsViewModel {
    func bind(contentPublisher: AnyPublisher<Content, Never>) {
        updatesSubscription = contentPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, content in
                viewModel.updateContent(content)
            }
    }

    func updateContent(_ content: Content) {
        self.content = content

        if answer == .awaiting, !isSigning {
            answer = content.answer
        }

        if case .signers(let signersViewModel) = viewState {
            signersViewModel.update(membersCount: content.membersCount, signers: content.signers)
        }
    }

    func close() {
        guard !isClosing else {
            return
        }

        isClosing = true
        frequentUpdatesSubscription = nil
        coordinator?.closeOperationDetails()
    }
}

// MARK: - Signers

private extension JointAccountOperationDetailsViewModel {
    func openSigners() {
        let viewModel = JointAccountSignersViewModel(
            membersCount: content.membersCount,
            signers: content.signers,
            coordinator: self
        )

        viewState = .signers(viewModel)
    }
}

// MARK: - Copying

private extension JointAccountOperationDetailsViewModel {
    func copy(_ value: String, toast text: String) {
        UIPasteboard.general.string = value
        FeedbackGenerator.selectionChanged()

        Toast(
            view: TangemSnackbar(title: text)
                .icon(DesignSystem.Icons.Checkmark.regular20)
                .iconColor(Color.Tangem.Graphic.Status.accent)
        )
        .present(layout: .top(padding: 14), type: .temporary())
    }
}

// MARK: - JointAccountSignersRoutable

extension JointAccountOperationDetailsViewModel: JointAccountSignersRoutable {
    func returnToOperationFromSigners() {
        viewState = .details
    }

    func closeSigners() {
        close()
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

        if answer == .awaiting {
            answer = content.answer
        }

        guard !error.isCancellationError else {
            return
        }

        JointAccountsLogger.error("Failed to sign a joint account operation", error: error)
        alertPresenter.present(alert: JointAccountOperationSigningErrorAlert(error: error).alertBinder)
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
                    recipient,
                    blockiesImage: AddressBlockiesIconViewData(image: recipientBlockiesImage)
                ),
                copyAction: TransactionDetailsMenuFactory.copyAddressAction(for: recipient).action
            )
        )
    }

    var signaturesBlock: TransactionDetailsBlock {
        .signatures(
            TransactionDetailsSignaturesViewData(
                title: Localization.jointOperationSignaturesProgress(content.collectedSignaturesCount, content.requiredSignaturesCount),
                collectedCount: content.collectedSignaturesCount,
                requiredCount: content.requiredSignaturesCount
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

    var signBlock: TransactionDetailsBlock? {
        guard content.status == .awaitingSignatures else {
            return nil
        }

        return .action(
            TransactionDetailsActionButtonViewData(
                title: signTitle,
                icon: (isSignEnabled && hasNFCInteraction) ? DesignSystem.Icons.LogoTangem.regular20 : nil,
                style: .default,
                action: .signOperation,
                isBusy: isSigning,
                isEnabled: isSignEnabled
            )
        )
    }

    var signTitle: String {
        switch answer {
        case .awaiting: return Localization.commonSign
        case .signed: return Localization.jointOperationSigned
        case .declined: return Localization.jointOperationDeclined
        }
    }

    var isSignEnabled: Bool {
        guard content.canSign else {
            return false
        }

        switch answer {
        case .awaiting: return true
        case .signed, .declined: return false
        }
    }

    /// A member who declined is told the operation is not dead: the others can still reach the threshold without
    /// them, which is the whole point of a threshold below the member count.
    var footerBlock: TransactionDetailsBlock? {
        let requiredSignaturesCount = content.requiredSignaturesCount
        let membersCount = content.membersCount

        switch content.status {
        case .sending:
            return nil
        case .sent:
            return .caption(Localization.jointOperationSentFooter(content.collectedSignaturesCount, membersCount))
        case .awaitingSignatures:
            break
        }

        switch answer {
        case .awaiting:
            return .caption(Localization.jointOperationAutoSendsFooter(requiredSignaturesCount, membersCount))
        case .signed:
            return .caption(Localization.jointOperationSignedFooter(requiredSignaturesCount, membersCount))
        case .declined:
            return .caption(Localization.jointOperationDeclinedFooter(requiredSignaturesCount, membersCount))
        }
    }
}

// MARK: - Constants

private extension JointAccountOperationDetailsViewModel {
    enum Constants {
        static let networkFeeRowID = "joint_operation_network_fee"
        static let addressMenuSectionID = "joint_operation_address"
    }
}

// MARK: - Auxiliary types

extension JointAccountOperationDetailsViewModel {
    /// The sheet swaps its own content instead of stacking a second one, the way the fee selector does: the signers
    /// belong to the operation being read, not to a screen of their own.
    enum ViewState {
        case details
        case signers(JointAccountSignersViewModel)
    }

    /// What this member has already done about the operation.
    enum Answer {
        case awaiting
        case signed
        case declined
    }

    enum Status: Equatable {
        case awaitingSignatures
        case sending
        case sent(at: Date)
    }

    struct Content {
        /// Includes the initiator's signature, so it is never zero for an operation that exists.
        let collectedSignaturesCount: Int
        /// How many of the members have to sign for the operation to go through.
        let requiredSignaturesCount: Int
        /// Everyone on the account. Kept apart from the threshold because the copy needs both: the signatures row
        /// counts against the threshold, while the footers and the signers screen name the roster.
        let membersCount: Int
        /// Every member of the account with where they stand on the operation, laid out ahead of the tap that opens
        /// them.
        let signers: [JointAccountSignerRow.ViewData]
        let answer: Answer
        let canSign: Bool
        let status: Status
    }
}
