//
//  JointAccountOperationDetailsViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
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
    @Published private(set) var pendingOperation: JointAccountPendingOperation?
    @Published private(set) var isOperationAvailable = true
    @Published private(set) var recipientContext: RecipientContext

    /// While signatures are collected the icon and title stay neutral by design: the warning-coloured line under the
    /// title is what says the operation is still waiting, and repeating that in the title would say it twice.
    var header: TransactionDetailsHeaderViewData? { pendingOperation.map(makeHeader(for:)) }
    var blocks: [TransactionDetailsBlock] { pendingOperation.map(makeBlocks(for:)) ?? [] }

    private let handle: JointAccountPendingOperationHandle
    private let alertPresenter: AlertPresenter
    private let analyticsLogger: any JointAccountOperationAnalyticsLogger
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
        handle: JointAccountPendingOperationHandle,
        addressBookWallet: AddressBookWallet,
        recipientSource: JointAccountOperationRecipientSource,
        coordinator: JointAccountOperationDetailsRoutable?,
        analyticsLogger: any JointAccountOperationAnalyticsLogger,
        addressBookAnalyticsLogger: AddressBookAnalyticsLogger = CommonAddressBookAnalyticsLogger(),
        alertPresenter: AlertPresenter = InjectedValues[\.alertPresenter]
    ) {
        self.handle = handle
        self.addressBookWallet = addressBookWallet
        self.recipientSource = recipientSource
        self.coordinator = coordinator
        self.addressBookAnalyticsLogger = addressBookAnalyticsLogger
        self.alertPresenter = alertPresenter
        self.analyticsLogger = analyticsLogger
        signingActionButtonType = SigningActionButtonViewTypeBuilder().build(userWalletInfo: addressBookWallet.wallet)
        recipientContext = RecipientContext(contacts: recipientSource.contacts, isAddressBookSynced: false, tangemPayDepositOwners: [])

        bind()
    }

    func onAppear() {
        frequentUpdatesSubscription = handle.requestFrequentUpdates()
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
        guard !isProcessing, isOperationAvailable else {
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
        let pendingOperationPublisher = handle.pendingOperationPublisher
            .receiveOnMain()
            .share(replay: 1)

        pendingOperationPublisher
            .filter { $0 != nil }
            .assign(to: &$pendingOperation)

        pendingOperationPublisher
            .map { $0 != nil }
            .assign(to: &$isOperationAvailable)

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
        guard let pendingOperation else {
            return
        }

        let viewModel = JointAccountSignersViewModel(pendingOperation: pendingOperation, handle: handle, coordinator: self)

        viewState = .signers(viewModel)
    }
}

// MARK: - Address book

private extension JointAccountOperationDetailsViewModel {
    func addressMenuActions(recipient: String, recipientState: RecipientState) -> [TransactionDetailsHeaderViewData.MenuAction] {
        let copyAddressAction = TransactionDetailsMenuFactory.copyAddressAction(for: recipient)

        guard recipientState.canAddToContacts else {
            return [copyAddressAction]
        }

        return [copyAddressAction, TransactionDetailsMenuFactory.addContactAction(for: recipient)]
    }

    func addContact(address: String) {
        guard let blockchain = pendingOperation?.tokenItem.blockchain else {
            return
        }

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
        guard !isProcessing, isOperationAvailable, let pendingOperation, pendingOperation.canSign else {
            return
        }

        isProcessing = true

        runTask(in: self) { viewModel in
            await viewModel.sign(pendingOperation)
        }
    }

    @MainActor
    func sign(_ pendingOperation: JointAccountPendingOperation) async {
        defer { isProcessing = false }

        do {
            let operation = try await handle.sign(pendingOperation)
            analyticsLogger.logOperationSigned(operation)
        } catch let error where error.isCancellationError {
            return
        } catch {
            JointAccountsLogger.error("Failed to sign a joint account operation", error: error)
            analyticsLogger.logSigningFailed(error: error)
            alertPresenter.present(alert: JointAccountOperationSigningErrorAlert(error: error).alertBinder)
        }
    }
}

// MARK: - Rejecting

private extension JointAccountOperationDetailsViewModel {
    func confirmRejection() {
        guard !isProcessing, isOperationAvailable, let pendingOperation else {
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

        let isInitiator = pendingOperation?.initiator.isMe == true

        do {
            try await handle.reject()
        } catch let error where error.isCancellationError {
            return
        } catch let error as TangemAPIError where error.code == .notFound {
            close()
            return
        } catch let error as TangemAPIError where error.code == .conflict {
            JointAccountsLogger.error("Failed to reject a joint account operation", error: error)
            analyticsLogger.logRejectionFailed(error: error, isInitiator: isInitiator)
            alertPresenter.present(alert: AlertBuilder.makeAlertWithDefaultPrimaryButton(
                title: Localization.jointOperationThresholdReachedTitle,
                message: Localization.jointOperationThresholdReachedSubtitle,
                buttonText: Localization.commonGotIt,
                buttonAction: { [weak self] in self?.close() }
            ))
            return
        } catch {
            JointAccountsLogger.error("Failed to reject a joint account operation", error: error)
            analyticsLogger.logRejectionFailed(error: error, isInitiator: isInitiator)
            alertPresenter.present(alert: JointAccountOperationSigningErrorAlert(error: error).alertBinder)
            return
        }

        guard isInitiator else {
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
    func makeHeader(for pendingOperation: JointAccountPendingOperation) -> TransactionDetailsHeaderViewData {
        let operationStatus = status(of: pendingOperation)
        let recipientState = makeRecipientState(for: pendingOperation)

        return TransactionDetailsHeaderViewData(
            title: headerTitle(status: operationStatus, recipientState: recipientState),
            titleStyle: headerTitleStyle(status: operationStatus),
            date: headerSubtitle(status: operationStatus),
            subtitleStyle: operationStatus == .awaitingSignatures ? .warning : .secondary,
            operationIcon: TransactionViewIconViewData(
                type: .transfer,
                status: headerIconStatus(status: operationStatus),
                isOutgoing: true
            ),
            iconGlyph: nil,
            menuSections: [
                .init(
                    id: Constants.addressMenuSectionID,
                    actions: addressMenuActions(recipient: recipient(of: pendingOperation), recipientState: recipientState)
                ),
                rejectMenuSection(for: pendingOperation),
            ].compactMap { $0 }
        )
    }

    func headerTitle(status: Status, recipientState: RecipientState) -> String {
        switch status {
        case .awaitingSignatures: Localization.commonSend
        case .sending, .sent, .failed:
            TransactionDisplayModel.title(
                transactionType: .transfer,
                status: headerIconStatus(status: status),
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

    func headerTitleStyle(status: Status) -> TransactionDetailsHeaderViewData.TitleStyle {
        switch status {
        case .sending: .active
        case .failed: .failed
        case .awaitingSignatures, .sent, .cancelled: .neutral
        }
    }

    func headerSubtitle(status: Status) -> String {
        switch status {
        case .awaitingSignatures: Localization.transactionHistoryPending
        case .sending: Localization.jointOperationSendingToNetwork
        case .sent(let date), .failed(let date), .cancelled(let date):
            TransactionDetailsFactory.headerDateFormatter.string(from: date)
        }
    }

    func headerIconStatus(status: Status) -> TransactionViewModel.Status {
        switch status {
        case .sending: .inProgress
        case .failed: .failed
        case .awaitingSignatures, .sent, .cancelled: .confirmed
        }
    }

    func rejectMenuSection(for pendingOperation: JointAccountPendingOperation) -> TransactionDetailsHeaderViewData.MenuSection? {
        guard isOperationAvailable, pendingOperation.canReject else {
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
    func makeBlocks(for pendingOperation: JointAccountPendingOperation) -> [TransactionDetailsBlock] {
        [
            makeTokenBlock(for: pendingOperation),
            makeRecipientBlock(for: pendingOperation),
            makeSignaturesBlock(for: pendingOperation),
            makeFeeBlock(for: pendingOperation),
            makeActionsBlock(for: pendingOperation),
            makeFooterBlock(for: pendingOperation),
        ].compactMap { $0 }
    }

    func makeTokenBlock(for pendingOperation: JointAccountPendingOperation) -> TransactionDetailsBlock {
        .tokens(
            TransactionDetailsTokensViewData(
                icon: .token(makeTokenIconInfo(for: pendingOperation)),
                caption: nil,
                amountText: cryptoAmount(of: pendingOperation),
                fiatText: makeFiatAmount(for: pendingOperation),
                isAmountStrikethrough: status(of: pendingOperation).isFailed
            )
        )
    }

    func makeRecipientBlock(for pendingOperation: JointAccountPendingOperation) -> TransactionDetailsBlock {
        let owner = makeRecipientState(for: pendingOperation).owner
        return .counterparty(TransactionDetailsFactory.counterparty(for: owner, label: Localization.sendRecipient))
    }

    func makeSignaturesBlock(for pendingOperation: JointAccountPendingOperation) -> TransactionDetailsBlock {
        let signersCount = requiredSignaturesCount(of: pendingOperation)

        return .signatures(
            TransactionDetailsSignaturesViewData(
                title: Localization.jointOperationSignaturesProgress(pendingOperation.collectedSignaturesCount, signersCount),
                collectedCount: pendingOperation.collectedSignaturesCount,
                requiredCount: signersCount
            )
        )
    }

    func makeFeeBlock(for pendingOperation: JointAccountPendingOperation) -> TransactionDetailsBlock {
        .info(
            TransactionDetailsInfoSectionViewData(
                rows: [
                    TransactionDetailsInfoSectionViewData.Row(
                        id: Constants.networkFeeRowID,
                        title: Localization.commonNetworkFeeTitle,
                        content: .sensitiveText(makeNetworkFee(for: pendingOperation))
                    ),
                ]
            )
        )
    }

    func makeActionsBlock(for pendingOperation: JointAccountPendingOperation) -> TransactionDetailsBlock? {
        guard status(of: pendingOperation) == .awaitingSignatures else {
            return nil
        }

        return .action(
            TransactionDetailsActionButtonViewData(
                id: signActionID(for: pendingOperation),
                title: signTitle(for: pendingOperation),
                icon: nil,
                style: .default,
                action: .signOperation,
                isBusy: isProcessing,
                isEnabled: isOperationAvailable && pendingOperation.canSign,
                signingType: signingActionButtonType
            )
        )
    }

    func signTitle(for pendingOperation: JointAccountPendingOperation) -> String {
        switch pendingOperation.standing {
        case .noDecisionYet, .unavailable, .unreadable: return Localization.commonSign
        case .signed: return Localization.jointOperationSigned
        case .declined: return Localization.jointOperationDeclined
        }
    }

    func signActionID(for pendingOperation: JointAccountPendingOperation) -> String {
        let operation = pendingOperation.operation
        return "\(operation.id)_\(operation.chainId)_\(operation.safeTransaction.hashValue)"
    }

    /// A member who declined is told the operation is not dead: the others can still reach the threshold without
    /// them, which is the whole point of a threshold below the member count.
    func makeFooterBlock(for pendingOperation: JointAccountPendingOperation) -> TransactionDetailsBlock? {
        let signersCount = requiredSignaturesCount(of: pendingOperation)
        let allMembersCount = membersCount(of: pendingOperation)

        switch status(of: pendingOperation) {
        case .sending, .failed, .cancelled:
            return nil
        case .sent:
            return .caption(Localization.jointOperationSentFooter(pendingOperation.collectedSignaturesCount, allMembersCount))
        case .awaitingSignatures:
            break
        }

        switch pendingOperation.standing {
        case .noDecisionYet, .unavailable, .unreadable:
            return .caption(Localization.jointOperationAutoSendsFooter(signersCount, allMembersCount))
        case .signed:
            return .caption(Localization.jointOperationSignedFooter(signersCount, allMembersCount))
        case .declined:
            return .caption(Localization.jointOperationDeclinedFooter(signersCount, allMembersCount))
        }
    }
}

// MARK: - Content

private extension JointAccountOperationDetailsViewModel {
    /// Written out for display, and taken from the payload's own `value` rather than from a field on the response.
    func cryptoAmount(of pendingOperation: JointAccountPendingOperation) -> String {
        transactionViewModelBuilder.cryptoAmount(of: pendingOperation)
    }

    /// Taken from the payload's own `to`.
    func recipient(of pendingOperation: JointAccountPendingOperation) -> String {
        pendingOperation.destination
    }

    func status(of pendingOperation: JointAccountPendingOperation) -> Status {
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
    func requiredSignaturesCount(of pendingOperation: JointAccountPendingOperation) -> Int {
        pendingOperation.wallet.account?.policy.signersCount ?? 0
    }

    /// Everyone on the account. Kept apart from the threshold because the copy needs both: the signatures row
    /// counts against the threshold, while the footers and the signers screen name the roster.
    func membersCount(of pendingOperation: JointAccountPendingOperation) -> Int {
        pendingOperation.wallet.account?.policy.membersCount ?? 0
    }

    func makeTokenIconInfo(for pendingOperation: JointAccountPendingOperation) -> TokenIconInfo {
        tokenIconInfoBuilder.build(from: pendingOperation.tokenItem, isCustom: pendingOperation.wallet.isCustom)
    }

    func makeFiatAmount(for pendingOperation: JointAccountPendingOperation) -> String {
        guard
            let value = pendingOperation.amount?.value,
            let currencyId = pendingOperation.tokenItem.currencyId,
            let fiat = balanceConverter.convertToFiat(value, currencyId: currencyId)
        else {
            return BalanceFormatter.defaultEmptyBalanceString
        }

        return balanceFormatter.formatFiatBalance(fiat)
    }

    func makeNetworkFee(for pendingOperation: JointAccountPendingOperation) -> String {
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

    func makeRecipientState(for pendingOperation: JointAccountPendingOperation) -> RecipientState {
        let userWalletId = addressBookWallet.wallet.id
        let blockchain = pendingOperation.tokenItem.blockchain
        let recipientAddress = recipient(of: pendingOperation)

        let subtitleOwnerResolver = SubtitleOwnerResolver(
            blockchain: blockchain,
            currentUserWalletId: userWalletId,
            // A wallet holding a joint account always has at least two accounts
            isAccountsMode: true,
            contacts: recipientContext.contacts,
            tangemPayDepositOwners: recipientContext.tangemPayDepositOwners
        )

        let owner = subtitleOwnerResolver.resolve(address: recipientAddress, blockchain: blockchain)

        let addContactHelper = TransactionDetailsAddContactHelper(
            networkId: AddressBookNetworkID(blockchain.networkId),
            contacts: recipientContext.contacts.filter { $0.walletId == userWalletId },
            isAddressBookSynced: recipientContext.isAddressBookSynced,
            transactionType: .transfer,
            interactionAddress: .user(recipientAddress),
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
