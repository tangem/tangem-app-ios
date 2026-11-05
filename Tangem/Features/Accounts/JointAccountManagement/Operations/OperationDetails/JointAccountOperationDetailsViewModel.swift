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
import TangemMacro
import TangemUI

/// An operation of a joint account laid out as the transaction details it will become once it is sent.
///
/// - Note: Handed an operation already read out of its signed payload. The sheet does no parsing, no digest of its
///   own and no signing — that belongs to the domain layer over the Safe support in the SDK.
final class JointAccountOperationDetailsViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Published private(set) var isProcessing = false
    @Published private(set) var viewState: ViewState = .details
    @Published private(set) var pendingOperation: JointAccountPendingOperation
    @Published private(set) var recipientContext: RecipientContext

    /// While signatures are collected the icon and title stay neutral by design: the warning-coloured line under the
    /// title is what says the operation is still waiting, and repeating that in the title would say it twice.
    var header: TransactionDetailsHeaderViewData { makeHeader() }
    var tokenBlock: TransactionDetailsBlock { makeTokenBlock() }
    var recipientBlock: TransactionDetailsBlock { makeRecipientBlock() }
    var signaturesBlock: TransactionDetailsBlock { makeSignaturesBlock() }
    var feeBlock: TransactionDetailsBlock { makeFeeBlock() }
    var actionsBlock: TransactionDetailsBlock? { makeActionsBlock() }
    var footerBlock: TransactionDetailsBlock? { makeFooterBlock() }

    var blocks: [TransactionDetailsBlock] {
        [
            tokenBlock,
            recipientBlock,
            signaturesBlock,
            feeBlock,
            actionsBlock,
            footerBlock,
        ].compactMap { $0 }
    }

    private let alertPresenter: AlertPresenter
    private let blockchain: BSDKBlockchain
    private let addressBookWallet: AddressBookWallet
    private let recipientSource: JointAccountOperationRecipientSource
    private let addressBookAnalyticsLogger: AddressBookAnalyticsLogger
    private let balanceFormatter = BalanceFormatter()
    private let balanceConverter = BalanceConverter()
    private let tokenIconInfoBuilder = TokenIconInfoBuilder()
    private let transactionViewModelBuilder = JointAccountOperationTransactionViewModelBuilder()
    private let signingActionButtonType: SigningActionButtonViewType
    private let copyHelper = JointAccountCopyHelper()
    private weak var coordinator: JointAccountOperationDetailsRoutable?
    private var frequentUpdatesSubscription: AnyCancellable?

    init(
        pendingOperation: JointAccountPendingOperation,
        addressBookWallet: AddressBookWallet,
        recipientSource: JointAccountOperationRecipientSource,
        coordinator: JointAccountOperationDetailsRoutable?,
        addressBookAnalyticsLogger: AddressBookAnalyticsLogger = CommonAddressBookAnalyticsLogger(),
        alertPresenter: AlertPresenter = InjectedValues[\.alertPresenter]
    ) {
        self.pendingOperation = pendingOperation
        self.addressBookWallet = addressBookWallet
        self.recipientSource = recipientSource
        self.coordinator = coordinator
        self.addressBookAnalyticsLogger = addressBookAnalyticsLogger
        self.alertPresenter = alertPresenter
        blockchain = pendingOperation.tokenItem.blockchain
        signingActionButtonType = SigningActionButtonViewTypeBuilder().build(userWalletInfo: addressBookWallet.wallet)
        recipientContext = RecipientContext(contacts: recipientSource.contacts, isAddressBookSynced: false, tangemPayDepositOwners: [])

        bind()
    }

    func onAppear() {
        frequentUpdatesSubscription = pendingOperation.requestFrequentUpdates()
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
        case .rejectOperation:
            confirmRejection()
        case .openSigners:
            openSigners()
        case .copy(let value, let toast, _):
            copyHelper.copy(value, toast: toast)
        case .addContact(let address):
            addContact(address: address)
        default:
            break
        }
    }

    func rejectOperation() {
        guard !isProcessing else {
            return
        }

        isProcessing = true

        runTask(in: self) { viewModel in
            await viewModel.reject()
        }
    }
}

// MARK: - Updates

private extension JointAccountOperationDetailsViewModel {
    func bind() {
        pendingOperation.didChangePublisher
            .receiveOnMain()
            .assign(to: &$pendingOperation)

        recipientSource.contactsPublisher
            .removeDuplicates()
            .combineLatest(
                recipientSource.isAddressBookSyncedPublisher.removeDuplicates(),
                recipientSource.tangemPayDepositOwnersPublisher
            )
            .map { contacts, isAddressBookSynced, tangemPayDepositOwners in
                RecipientContext(
                    contacts: contacts,
                    isAddressBookSynced: isAddressBookSynced,
                    tangemPayDepositOwners: tangemPayDepositOwners
                )
            }
            .removeDuplicates()
            .receiveOnMain()
            .assign(to: &$recipientContext)
    }

    func close() {
        frequentUpdatesSubscription = nil
        coordinator?.closeOperationDetails()
    }
}

// MARK: - Signers

private extension JointAccountOperationDetailsViewModel {
    func openSigners() {
        let viewModel = JointAccountSignersViewModel(pendingOperation: pendingOperation, coordinator: self)

        viewState = .signers(viewModel)
    }
}

// MARK: - Address book

private extension JointAccountOperationDetailsViewModel {
    var addressMenuActions: [TransactionDetailsHeaderViewData.MenuAction] {
        let copyAddressAction = TransactionDetailsMenuFactory.copyAddressAction(for: recipient)

        guard recipientState.canAddToContacts else {
            return [copyAddressAction]
        }

        return [copyAddressAction, TransactionDetailsMenuFactory.addContactAction(for: recipient)]
    }

    func addContact(address: String) {
        addressBookAnalyticsLogger.logAddContactTapped(source: .transactionDetails)

        let entry = AddressBookEntryDraft(address: address, blockchain: blockchain, memo: nil)
        coordinator?.openAddContactFromOperationDetails(addressBookWallet: addressBookWallet, prefilledEntries: [entry])
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
        guard !isProcessing else {
            return
        }

        isProcessing = true

        runTask(in: self) { viewModel in
            await viewModel.sign()
        }
    }

    @MainActor
    func sign() async {
        defer { isProcessing = false }

        do {
            try await pendingOperation.sign()
        } catch let error where error.isCancellationError {
            return
        } catch {
            JointAccountsLogger.error("Failed to sign a joint account operation", error: error)
            alertPresenter.present(alert: JointAccountOperationSigningErrorAlert(error: error).alertBinder)
        }
    }
}

// MARK: - Rejecting

private extension JointAccountOperationDetailsViewModel {
    func confirmRejection() {
        guard !isProcessing else {
            return
        }

        let isInitiator = pendingOperation.initiator.isMe

        alertPresenter.present(alert: AlertBuilder.makeAlert(
            title: isInitiator ? Localization.jointOperationDeleteAlertTitle : Localization.jointOperationDeclineAlertTitle,
            message: isInitiator ? Localization.jointOperationDeleteAlertMessage : Localization.jointOperationDeclineAlertMessage,
            primaryButton: .destructive(Text(isInitiator ? Localization.commonDelete : Localization.commonDecline)) { [weak self] in
                self?.rejectOperation()
            },
            secondaryButton: .cancel()
        ))
    }

    @MainActor
    func reject() async {
        defer { isProcessing = false }

        do {
            try await pendingOperation.reject()
        } catch let error where error.isCancellationError {
            return
        } catch let error as TangemAPIError where error.code == .notFound {
            close()
            return
        } catch let error as TangemAPIError where error.code == .conflict {
            JointAccountsLogger.error("Failed to reject a joint account operation", error: error)
            alertPresenter.present(alert: AlertBuilder.makeAlertWithDefaultPrimaryButton(
                title: Localization.jointOperationThresholdReachedTitle,
                message: Localization.jointOperationThresholdReachedSubtitle,
                buttonText: Localization.commonGotIt,
                buttonAction: { [weak self] in self?.close() }
            ))
            return
        } catch {
            JointAccountsLogger.error("Failed to reject a joint account operation", error: error)
            alertPresenter.present(alert: JointAccountOperationSigningErrorAlert(error: error).alertBinder)
            return
        }

        guard pendingOperation.initiator.isMe else {
            return
        }

        close()
        showDeletedToast()
    }

    func showDeletedToast() {
        Toast(
            view: TangemSnackbar(title: Localization.jointOperationDeletedSnackbar)
                .icon(DesignSystem.Icons.TrashBin.regular20)
                .iconColor(DesignSystem.Color.iconStatusError)
        )
        .present(layout: .top(padding: 14), type: .temporary())
    }
}

// MARK: - Header

private extension JointAccountOperationDetailsViewModel {
    func makeHeader() -> TransactionDetailsHeaderViewData {
        TransactionDetailsHeaderViewData(
            title: headerTitle,
            titleStyle: headerTitleStyle,
            date: headerSubtitle,
            subtitleStyle: status == .awaitingSignatures ? .warning : .secondary,
            operationIcon: TransactionViewIconViewData(
                type: .transfer,
                status: headerIconStatus,
                isOutgoing: true
            ),
            iconGlyph: nil,
            menuSections: [
                .init(id: Constants.addressMenuSectionID, actions: addressMenuActions),
                rejectMenuSection,
            ].compactMap { $0 }
        )
    }

    var headerTitle: String {
        switch status {
        case .awaitingSignatures: Localization.commonSend
        case .sending, .sent, .failed:
            TransactionDisplayModel.title(
                transactionType: .transfer,
                status: headerIconStatus,
                isOutgoing: true,
                isFromYieldContract: false,
                legacyName: Localization.commonTransfer,
                subtitleOwner: recipientState.owner,
                isTangemPayCounterparty: false
            ).fullText
        // [REDACTED_TODO_COMMENT]
        case .cancelled: Localization.expressExchangeStatusCanceled
        }
    }

    var headerTitleStyle: TransactionDetailsHeaderViewData.TitleStyle {
        switch status {
        case .sending: .active
        case .failed: .failed
        case .awaitingSignatures, .sent, .cancelled: .neutral
        }
    }

    var headerSubtitle: String {
        switch status {
        case .awaitingSignatures: Localization.transactionHistoryPending
        case .sending: Localization.jointOperationSendingToNetwork
        case .sent(let date), .failed(let date), .cancelled(let date):
            TransactionDetailsFactory.headerDateFormatter.string(from: date)
        }
    }

    var headerIconStatus: TransactionViewModel.Status {
        switch status {
        case .sending: .inProgress
        case .failed: .failed
        case .awaitingSignatures, .sent, .cancelled: .confirmed
        }
    }

    var rejectMenuSection: TransactionDetailsHeaderViewData.MenuSection? {
        guard pendingOperation.canReject else {
            return nil
        }

        let action = TransactionDetailsHeaderViewData.MenuAction(
            id: Constants.rejectMenuActionID,
            title: pendingOperation.initiator.isMe ? Localization.commonDelete : Localization.commonDecline,
            icon: pendingOperation.initiator.isMe ? DesignSystem.Icons.TrashBin.regular24 : DesignSystem.Icons.Cross.regular24,
            action: .rejectOperation,
            role: .destructive
        )

        return .init(id: Constants.rejectMenuSectionID, actions: [action])
    }
}

// MARK: - Blocks

private extension JointAccountOperationDetailsViewModel {
    func makeTokenBlock() -> TransactionDetailsBlock {
        .tokens(
            TransactionDetailsTokensViewData(
                icon: .token(tokenIconInfo),
                caption: nil,
                amountText: cryptoAmount,
                fiatText: fiatAmount,
                isAmountStrikethrough: status.isFailed
            )
        )
    }

    func makeRecipientBlock() -> TransactionDetailsBlock {
        .counterparty(TransactionDetailsFactory.counterparty(for: recipientState.owner, label: Localization.sendRecipient))
    }

    func makeSignaturesBlock() -> TransactionDetailsBlock {
        .signatures(
            TransactionDetailsSignaturesViewData(
                title: Localization.jointOperationSignaturesProgress(pendingOperation.collectedSignaturesCount, requiredSignaturesCount),
                collectedCount: pendingOperation.collectedSignaturesCount,
                requiredCount: requiredSignaturesCount
            )
        )
    }

    func makeFeeBlock() -> TransactionDetailsBlock {
        .info(
            TransactionDetailsInfoSectionViewData(
                rows: [
                    TransactionDetailsInfoSectionViewData.Row(
                        id: Constants.networkFeeRowID,
                        title: Localization.commonNetworkFeeTitle,
                        content: .sensitiveText(networkFee)
                    ),
                ]
            )
        )
    }

    func makeActionsBlock() -> TransactionDetailsBlock? {
        guard status == .awaitingSignatures else {
            return nil
        }

        return .action(
            TransactionDetailsActionButtonViewData(
                title: signTitle,
                icon: nil,
                style: .default,
                action: .signOperation,
                isBusy: isProcessing,
                isEnabled: pendingOperation.canSign,
                signingType: signingActionButtonType
            )
        )
    }

    var signTitle: String {
        switch pendingOperation.standing {
        case .noDecisionYet, .unavailable, .unreadable: return Localization.commonSign
        case .signed: return Localization.jointOperationSigned
        case .declined: return Localization.jointOperationDeclined
        }
    }

    /// A member who declined is told the operation is not dead: the others can still reach the threshold without
    /// them, which is the whole point of a threshold below the member count.
    func makeFooterBlock() -> TransactionDetailsBlock? {
        switch status {
        case .sending, .failed, .cancelled:
            return nil
        case .sent:
            return .caption(Localization.jointOperationSentFooter(pendingOperation.collectedSignaturesCount, membersCount))
        case .awaitingSignatures:
            break
        }

        switch pendingOperation.standing {
        case .noDecisionYet, .unavailable, .unreadable:
            return .caption(Localization.jointOperationAutoSendsFooter(requiredSignaturesCount, membersCount))
        case .signed:
            return .caption(Localization.jointOperationSignedFooter(requiredSignaturesCount, membersCount))
        case .declined:
            return .caption(Localization.jointOperationDeclinedFooter(requiredSignaturesCount, membersCount))
        }
    }
}

// MARK: - Content

private extension JointAccountOperationDetailsViewModel {
    var tokenIconInfo: TokenIconInfo { makeTokenIconInfo() }
    /// Written out for display, and taken from the payload's own `value` rather than from a field on the response.
    var cryptoAmount: String { transactionViewModelBuilder.cryptoAmount(of: pendingOperation) }
    var fiatAmount: String { makeFiatAmount() }
    /// Taken from the payload's own `to`.
    var recipient: String { pendingOperation.destination }
    var networkFee: String { makeNetworkFee() }
    var recipientState: RecipientState { makeRecipientState() }

    var status: Status {
        let finishedAt = pendingOperation.finishedAt ?? Date()

        return switch pendingOperation.status {
        case .awaitingSignatures: .awaitingSignatures
        case .pending: .sending
        case .executed: .sent(at: finishedAt)
        case .failed: .failed(at: finishedAt)
        case .cancelled, .unknown: .cancelled(at: finishedAt)
        }
    }

    /// How many of the members have to sign for the operation to go through.
    var requiredSignaturesCount: Int {
        pendingOperation.wallet.account?.policy.signersCount ?? 0
    }

    /// Everyone on the account. Kept apart from the threshold because the copy needs both: the signatures row
    /// counts against the threshold, while the footers and the signers screen name the roster.
    var membersCount: Int {
        pendingOperation.wallet.account?.policy.membersCount ?? 0
    }

    func makeTokenIconInfo() -> TokenIconInfo {
        tokenIconInfoBuilder.build(from: pendingOperation.tokenItem, isCustom: pendingOperation.wallet.isCustom)
    }

    func makeFiatAmount() -> String {
        guard
            let value = pendingOperation.amount?.value,
            let currencyId = pendingOperation.tokenItem.currencyId,
            let fiat = balanceConverter.convertToFiat(value, currencyId: currencyId)
        else {
            return BalanceFormatter.defaultEmptyBalanceString
        }

        return balanceFormatter.formatFiatBalance(fiat)
    }

    func makeNetworkFee() -> String {
        guard let fee = pendingOperation.fee else {
            return BalanceFormatter.defaultEmptyBalanceString
        }

        let formattedFee = balanceFormatter.formatCryptoBalance(
            fee.value,
            currencyCode: fee.currencySymbol,
            formattingOptions: .sendCryptoFeeFormattingOptions
        )

        return fee.value > 0 ? AppConstants.tildeSign + formattedFee : formattedFee
    }

    func makeRecipientState() -> RecipientState {
        let userWalletId = addressBookWallet.wallet.id

        let subtitleOwnerResolver = SubtitleOwnerResolver(
            blockchain: blockchain,
            currentUserWalletId: userWalletId,
            // A wallet holding a joint account always has at least two accounts
            isAccountsMode: true,
            contacts: recipientContext.contacts,
            tangemPayDepositOwners: recipientContext.tangemPayDepositOwners
        )

        let owner = subtitleOwnerResolver.resolve(address: recipient, blockchain: blockchain)

        let addContactHelper = TransactionDetailsAddContactHelper(
            networkId: AddressBookNetworkID(blockchain.networkId),
            contacts: recipientContext.contacts.filter { $0.walletId == userWalletId },
            isAddressBookSynced: recipientContext.isAddressBookSynced,
            transactionType: .transfer,
            interactionAddress: .user(recipient),
            subtitleOwner: owner
        )

        return RecipientState(owner: owner, canAddToContacts: addContactHelper.addressToSave() != nil)
    }
}

// MARK: - Constants

private extension JointAccountOperationDetailsViewModel {
    enum Constants {
        static let networkFeeRowID = "joint_operation_network_fee"
        static let addressMenuSectionID = "joint_operation_address"
        static let rejectMenuSectionID = "joint_operation_reject"
        static let rejectMenuActionID = "rejectOperation"
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

    struct RecipientState: Equatable {
        let owner: TransactionViewModel.SubtitleOwner
        let canAddToContacts: Bool
    }

    @CaseFlagable
    enum Status: Equatable {
        case awaitingSignatures
        case sending
        case sent(at: Date)
        case failed(at: Date)
        case cancelled(at: Date)
    }

    struct RecipientContext: Equatable {
        let contacts: [AddressBookContact]
        let isAddressBookSynced: Bool
        let tangemPayDepositOwners: [TangemPayDepositOwner]
    }
}
