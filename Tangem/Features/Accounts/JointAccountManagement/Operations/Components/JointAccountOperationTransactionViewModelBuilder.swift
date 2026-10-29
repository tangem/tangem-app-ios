//
//  JointAccountOperationTransactionViewModelBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct JointAccountOperationTransactionViewModelBuilder {
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    private let balanceFormatter = BalanceFormatter()

    func build(
        pendingOperation: JointAccountPendingOperation,
        subtitleOwnerResolver: SubtitleOwnerResolver?
    ) -> TransactionViewModel {
        let operation = pendingOperation.operation
        let tokenItem = pendingOperation.tokenItem
        let destination = pendingOperation.destination
        let interactionAddress: TransactionViewModel.InteractionAddressType = .user(destination)
        let amount = pendingOperation.amount?.value

        return TransactionViewModel(
            hash: operation.id,
            index: 0,
            interactionAddress: interactionAddress,
            timeFormatted: startedAt(of: operation).map(Self.timeFormatter.string(from:)),
            amount: cryptoAmount(of: pendingOperation),
            value: sign(of: amount) + balanceFormatter.formatDecimal(amount),
            currencyCode: tokenItem.currencySymbol,
            isOutgoing: true,
            transactionType: .transfer,
            status: .inProgress,
            isFromYieldContract: false,
            subtitleOwner: subtitleOwnerResolver?.resolve(address: destination, blockchain: tokenItem.blockchain),
            isTangemPayCounterparty: subtitleOwnerResolver?.isTangemPayDeposit(interactionAddress) == true,
            isPendingSignature: operation.status == .awaitingSignatures
        )
    }

    /// - Note: Signed as an outgoing transfer, so it is stated as one — an amount this version cannot read is shown
    ///   the way an unknown balance is rather than as a number that understates what the member is signing.
    func cryptoAmount(of pendingOperation: JointAccountPendingOperation) -> String {
        let amount = pendingOperation.amount?.value
        return sign(of: amount) + balanceFormatter.formatCryptoBalance(amount, tokenItem: pendingOperation.tokenItem)
    }

    private func sign(of amount: Decimal?) -> String {
        amount == nil ? "" : AppConstants.minusSign
    }

    private func startedAt(of operation: JointAccountOperation) -> Date? {
        guard let answer = operation.signatures.first(where: { $0.address.caseInsensitiveEquals(to: operation.initiator) }) else {
            return nil
        }

        return RelativeDateFormatter.shared.parseDate(from: answer.at)
    }
}
