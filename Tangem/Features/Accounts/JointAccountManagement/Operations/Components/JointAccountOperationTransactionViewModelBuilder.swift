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

    private static let answerDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let answerDateFallbackFormatter = ISO8601DateFormatter()

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

        let sign = amount == nil ? "" : AppConstants.minusSign

        return TransactionViewModel(
            hash: operation.id,
            index: 0,
            interactionAddress: interactionAddress,
            timeFormatted: startedAt(of: operation).map(Self.timeFormatter.string(from:)),
            amount: sign + balanceFormatter.formatCryptoBalance(amount, tokenItem: tokenItem),
            value: sign + balanceFormatter.formatDecimal(amount),
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

    private func startedAt(of operation: JointAccountOperation) -> Date? {
        guard let answer = operation.signatures.first(where: { $0.address.caseInsensitiveEquals(to: operation.initiator) }) else {
            return nil
        }

        return Self.answerDateFormatter.date(from: answer.at) ?? Self.answerDateFallbackFormatter.date(from: answer.at)
    }
}
