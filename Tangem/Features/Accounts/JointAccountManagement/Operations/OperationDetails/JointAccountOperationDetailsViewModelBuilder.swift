//
//  JointAccountOperationDetailsViewModelBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

/// Reads an unfinished operation into the sheet that asks a member to sign it.
///
/// - Note: Everything comes from the payload the signature covers — the amount and the recipient off the inner call,
///   the fee off the Safe transaction — rather than from display fields of the response.
struct JointAccountOperationDetailsViewModelBuilder {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let balanceFormatter = BalanceFormatter()
    private let balanceConverter = BalanceConverter()
    private let tokenIconInfoBuilder = TokenIconInfoBuilder()
    private let transactionViewModelBuilder = JointAccountOperationTransactionViewModelBuilder()
    private let signersBuilder = JointAccountSignersViewDataBuilder()
    private let standingResolver = JointAccountPendingOperationStandingResolver()

    func build(
        pendingOperation: JointAccountPendingOperation,
        userWalletInfo: UserWalletInfo,
        addressBookManager: AddressBookManager,
        coordinator: JointAccountOperationDetailsRoutable?
    ) -> JointAccountOperationDetailsViewModel {
        let tokenItem = pendingOperation.tokenItem
        let addressBookWallet = AddressBookWallet(wallet: userWalletInfo, addressBookManager: addressBookManager)
        let initialRecipientState = recipientState(
            of: pendingOperation,
            userWalletId: userWalletInfo.id,
            contacts: addressBookManager.contacts,
            isAddressBookSynced: false,
            tangemPayDepositOwners: []
        )

        return JointAccountOperationDetailsViewModel(
            tokenIconInfo: tokenIconInfoBuilder.build(from: tokenItem, isCustom: pendingOperation.wallet.isCustom),
            cryptoAmount: transactionViewModelBuilder.cryptoAmount(of: pendingOperation),
            fiatAmount: fiatAmount(of: pendingOperation),
            recipient: pendingOperation.destination,
            recipientState: initialRecipientState,
            blockchain: tokenItem.blockchain,
            networkFee: networkFee(of: pendingOperation),
            signingActionButtonType: SigningActionButtonViewTypeBuilder().build(userWalletInfo: userWalletInfo),
            content: content(of: pendingOperation),
            contentPublisher: contentPublisher(of: pendingOperation),
            addressBookWallet: addressBookWallet,
            addressBookAnalyticsLogger: CommonAddressBookAnalyticsLogger(),
            recipientStatePublisher: recipientStatePublisher(
                of: pendingOperation,
                userWalletId: userWalletInfo.id,
                contactsPublisher: AddressBookContactsAggregator.contactsPublisher(),
                syncStatePublisher: addressBookWallet.syncStatePublisher,
                tangemPayDepositOwnersPublisher: TangemPayDepositOwnersPublisherFactory.makePublisher(userWalletRepository: userWalletRepository)
            ),
            poller: pendingOperation,
            coordinator: coordinator,
            sign: { try await pendingOperation.sign() },
            reject: { try await pendingOperation.reject() }
        )
    }
}

// MARK: - Following the operation

extension JointAccountOperationDetailsViewModelBuilder {
    func contentPublisher(of pendingOperation: JointAccountPendingOperation) -> AnyPublisher<JointAccountOperationDetailsViewModel.Content, Never> {
        pendingOperation.operationPublisher
            .map { operation in content(of: pendingOperation.updating(operation: operation)) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Recipient

extension JointAccountOperationDetailsViewModelBuilder {
    func recipientStatePublisher(
        of pendingOperation: JointAccountPendingOperation,
        userWalletId: UserWalletId,
        contactsPublisher: some Publisher<[AddressBookContact], Never>,
        syncStatePublisher: some Publisher<AddressBookSyncState, Never>,
        tangemPayDepositOwnersPublisher: some Publisher<[TangemPayDepositOwner], Never>
    ) -> AnyPublisher<JointAccountOperationDetailsViewModel.RecipientState, Never> {
        contactsPublisher
            .removeDuplicates()
            .combineLatest(syncStatePublisher.map(\.isSynced).removeDuplicates(), tangemPayDepositOwnersPublisher)
            .receiveOnMain()
            .map { contacts, isAddressBookSynced, tangemPayDepositOwners in
                recipientState(
                    of: pendingOperation,
                    userWalletId: userWalletId,
                    contacts: contacts,
                    isAddressBookSynced: isAddressBookSynced,
                    tangemPayDepositOwners: tangemPayDepositOwners
                )
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension JointAccountOperationDetailsViewModelBuilder {
    func recipientState(
        of pendingOperation: JointAccountPendingOperation,
        userWalletId: UserWalletId,
        contacts: [AddressBookContact],
        isAddressBookSynced: Bool,
        tangemPayDepositOwners: [TangemPayDepositOwner]
    ) -> JointAccountOperationDetailsViewModel.RecipientState {
        let blockchain = pendingOperation.tokenItem.blockchain
        let recipient = pendingOperation.destination

        let subtitleOwnerResolver = SubtitleOwnerResolver(
            blockchain: blockchain,
            currentUserWalletId: userWalletId,
            // A wallet holding a joint account always has at least two accounts
            isAccountsMode: true,
            contacts: contacts,
            tangemPayDepositOwners: tangemPayDepositOwners
        )

        let owner = subtitleOwnerResolver.resolve(address: recipient, blockchain: blockchain)

        let addContactHelper = TransactionDetailsAddContactHelper(
            networkId: AddressBookNetworkID(blockchain.networkId),
            contacts: contacts.filter { $0.walletId == userWalletId },
            isAddressBookSynced: isAddressBookSynced,
            transactionType: .transfer,
            interactionAddress: .user(recipient),
            subtitleOwner: owner
        )

        return JointAccountOperationDetailsViewModel.RecipientState(
            owner: owner,
            canAddToContacts: addContactHelper.addressToSave() != nil
        )
    }

    func content(of pendingOperation: JointAccountPendingOperation) -> JointAccountOperationDetailsViewModel.Content {
        let account = pendingOperation.wallet.account

        return JointAccountOperationDetailsViewModel.Content(
            collectedSignaturesCount: pendingOperation.operation.signatures.filter { $0.state == .signed }.count,
            requiredSignaturesCount: account?.policy.signersCount ?? 0,
            membersCount: account?.jointAccountMembersService.slots.members.count ?? 0,
            signers: signersBuilder.build(pendingOperation: pendingOperation),
            answer: answer(of: pendingOperation),
            canSign: standingResolver.canSign(pendingOperation),
            canReject: standingResolver.canReject(pendingOperation),
            isInitiator: pendingOperation.initiator.isMe,
            status: status(of: pendingOperation)
        )
    }

    func status(of pendingOperation: JointAccountPendingOperation) -> JointAccountOperationDetailsViewModel.Status {
        let operation = pendingOperation.operation

        return switch operation.status {
        case .awaitingSignatures: .awaitingSignatures
        case .pending: .sending
        case .executed: .sent(at: operation.finishedAt ?? Date())
        case .failed: .failed(at: operation.finishedAt ?? Date())
        case .cancelled, .unknown: .cancelled(at: operation.finishedAt ?? Date())
        }
    }

    func answer(of pendingOperation: JointAccountPendingOperation) -> JointAccountOperationDetailsViewModel.Answer {
        switch standingResolver.standing(for: pendingOperation) {
        case .signed: .signed
        case .declined: .declined
        case .noDecisionYet: .awaiting
        }
    }

    func fiatAmount(of pendingOperation: JointAccountPendingOperation) -> String {
        guard
            let value = pendingOperation.amount?.value,
            let currencyId = pendingOperation.tokenItem.currencyId,
            let fiat = balanceConverter.convertToFiat(value, currencyId: currencyId)
        else {
            return BalanceFormatter.defaultEmptyBalanceString
        }

        return balanceFormatter.formatFiatBalance(fiat)
    }

    func networkFee(of pendingOperation: JointAccountPendingOperation) -> String {
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
}
