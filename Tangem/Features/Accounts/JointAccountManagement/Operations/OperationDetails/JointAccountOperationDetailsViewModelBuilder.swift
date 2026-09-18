//
//  JointAccountOperationDetailsViewModelBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Reads an unfinished operation into the sheet that asks a member to sign it.
///
/// - Note: Everything comes from the payload the signature covers — the amount and the recipient off the inner call,
///   the fee off the Safe transaction — rather than from display fields of the response.
struct JointAccountOperationDetailsViewModelBuilder {
    private let balanceFormatter = BalanceFormatter()
    private let balanceConverter = BalanceConverter()
    private let tokenIconInfoBuilder = TokenIconInfoBuilder()

    func build(
        pendingOperation: JointAccountPendingOperation,
        coordinator: JointAccountOperationDetailsRoutable?
    ) -> JointAccountOperationDetailsViewModel {
        let operation = pendingOperation.operation
        let account = pendingOperation.wallet.account
        let tokenItem = pendingOperation.tokenItem

        return JointAccountOperationDetailsViewModel(
            tokenIconInfo: tokenIconInfoBuilder.build(from: tokenItem, isCustom: pendingOperation.wallet.isCustom),
            cryptoAmount: cryptoAmount(of: pendingOperation),
            fiatAmount: fiatAmount(of: pendingOperation),
            recipient: AddressFormatter(address: pendingOperation.destination).truncated(),
            recipientBlockiesImage: AddressIconProvider.makeBlockiesImage(address: pendingOperation.destination),
            networkFee: networkFee(of: pendingOperation),
            collectedSignaturesCount: operation.signatures.filter { $0.state == .signed }.count,
            requiredSignaturesCount: account?.policy.signersCount ?? 0,
            membersCount: account?.jointAccountMembersService.slots.members.count ?? 0,
            // [REDACTED_TODO_COMMENT]
            // [REDACTED_INFO]
            answer: .awaiting,
            coordinator: coordinator,
            sign: { try await pendingOperation.sign() }
        )
    }
}

// MARK: - Private

private extension JointAccountOperationDetailsViewModelBuilder {
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
        balanceFormatter.formatCryptoBalance(
            pendingOperation.fee?.value,
            tokenItem: .blockchain(pendingOperation.tokenItem.blockchainNetwork)
        )
    }
}
