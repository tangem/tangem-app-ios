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
    private let balanceFormatter = BalanceFormatter()
    private let balanceConverter = BalanceConverter()
    private let tokenIconInfoBuilder = TokenIconInfoBuilder()
    private let signersBuilder = JointAccountSignersViewDataBuilder()
    private let signersResolver = JointAccountOperationSignersResolver()

    func build(
        pendingOperation: JointAccountPendingOperation,
        userWalletInfo: UserWalletInfo,
        coordinator: JointAccountOperationDetailsRoutable?
    ) -> JointAccountOperationDetailsViewModel {
        let provider = pendingOperation.wallet.account?.jointAccountPendingOperationsProvider
        let tokenItem = pendingOperation.tokenItem

        return JointAccountOperationDetailsViewModel(
            tokenIconInfo: tokenIconInfoBuilder.build(from: tokenItem, isCustom: pendingOperation.wallet.isCustom),
            cryptoAmount: cryptoAmount(of: pendingOperation),
            fiatAmount: fiatAmount(of: pendingOperation),
            recipient: pendingOperation.destination,
            recipientBlockiesImage: AddressIconProvider.makeBlockiesImage(address: pendingOperation.destination),
            networkFee: networkFee(of: pendingOperation),
            signingActionButtonType: SigningActionButtonViewTypeBuilder().build(userWalletInfo: userWalletInfo),
            content: content(of: pendingOperation),
            contentPublisher: contentPublisher(of: pendingOperation.operation.id, provider: provider),
            pendingOperationsProvider: provider,
            coordinator: coordinator,
            sign: { try await pendingOperation.sign() }
        )
    }
}

// MARK: - Following the listing

extension JointAccountOperationDetailsViewModelBuilder {
    func contentPublisher(
        of operationId: String,
        provider: (any JointAccountPendingOperationsProvider)?
    ) -> AnyPublisher<JointAccountOperationDetailsViewModel.Content, Never> {
        guard let provider else {
            return .empty
        }

        return provider
            .pendingOperationsPublisher
            .compactMap { operations in operations.first { $0.operation.id == operationId } }
            .removeDuplicates()
            .map { pendingOperation in content(of: pendingOperation) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension JointAccountOperationDetailsViewModelBuilder {
    func content(of pendingOperation: JointAccountPendingOperation) -> JointAccountOperationDetailsViewModel.Content {
        let account = pendingOperation.wallet.account

        return JointAccountOperationDetailsViewModel.Content(
            collectedSignaturesCount: pendingOperation.operation.signatures.filter { $0.state == .signed }.count,
            requiredSignaturesCount: account?.policy.signersCount ?? 0,
            membersCount: account?.jointAccountMembersService.slots.members.count ?? 0,
            signers: signersBuilder.build(pendingOperation: pendingOperation),
            answer: answer(of: pendingOperation),
            canSign: signersResolver.canSign(pendingOperation),
            status: status(of: pendingOperation)
        )
    }

    func status(of pendingOperation: JointAccountPendingOperation) -> JointAccountOperationDetailsViewModel.Status {
        switch pendingOperation.operation.status {
        case .pending: .sending
        case .executed: .sent(at: Date())
        case .awaitingSignatures, .failed, .cancelled, .unknown: .awaitingSignatures
        }
    }

    func answer(of pendingOperation: JointAccountPendingOperation) -> JointAccountOperationDetailsViewModel.Answer {
        switch signersResolver.ownAnswer(of: pendingOperation) {
        case .signed, .created: .signed
        case .declined: .declined
        case .waiting, .none: .awaiting
        }
    }

    /// - Note: Signed as an outgoing transfer, so it is stated as one — an amount this version cannot read is shown
    ///   the way an unknown balance is rather than as a number that understates what the member is signing.
    func cryptoAmount(of pendingOperation: JointAccountPendingOperation) -> String {
        let formatted = balanceFormatter.formatCryptoBalance(
            pendingOperation.amount?.value,
            tokenItem: pendingOperation.tokenItem
        )

        guard pendingOperation.amount?.value != nil else {
            return formatted
        }

        return AppConstants.minusSign + formatted
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
        guard let fee = pendingOperation.fee?.value else {
            return BalanceFormatter.defaultEmptyBalanceString
        }

        let formattedFee = balanceFormatter.formatCryptoBalance(
            fee,
            currencyCode: pendingOperation.tokenItem.blockchain.currencySymbol,
            formattingOptions: .sendCryptoFeeFormattingOptions
        )

        return fee > 0 ? AppConstants.tildeSign + formattedFee : formattedFee
    }
}
