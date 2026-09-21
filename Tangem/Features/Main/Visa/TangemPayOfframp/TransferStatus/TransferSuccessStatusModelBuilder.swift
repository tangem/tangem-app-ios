//
//  TransferSuccessStatusModelBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPay

enum TransferSuccessStatusModelBuilder {
    static func model(
        amount: Decimal?,
        date: Date,
        personalDetails: TangemPayOfframpPersonalDetails?,
        bankDetails: TangemPayOfframpBankDetails?,
        savedRecipient: TangemPayBankAccountResponse?
    ) -> TransferSuccessStatusView.Model {
        TransferSuccessStatusView.Model(
            title: title(amount: amount),
            dateText: dateFormatter.string(from: date),
            details: details(
                personalDetails: personalDetails,
                bankDetails: bankDetails,
                savedRecipient: savedRecipient
            )
        )
    }
}

// MARK: - Title

private extension TransferSuccessStatusModelBuilder {
    static func title(amount: Decimal?) -> String {
        guard let amount else {
            return Constants.titlePrefix
        }

        return "\(Constants.titlePrefix) \(TangemPayOfframpAmountFormatter.format(amount))"
    }

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Details

private extension TransferSuccessStatusModelBuilder {
    static func details(
        personalDetails: TangemPayOfframpPersonalDetails?,
        bankDetails: TangemPayOfframpBankDetails?,
        savedRecipient: TangemPayBankAccountResponse?
    ) -> [TransferSuccessStatusView.Detail] {
        if let savedRecipient {
            return details(savedRecipient: savedRecipient)
        }

        guard let personalDetails else {
            return []
        }

        return make(
            recipient: recipientName(for: personalDetails.name),
            bankName: bankDetails?.name,
            accountNumber: personalDetails.accountNumber
        )
    }

    static func details(savedRecipient: TangemPayBankAccountResponse) -> [TransferSuccessStatusView.Detail] {
        make(
            recipient: TangemPayRecipientNameFormatter.name(for: savedRecipient, style: .full),
            bankName: savedRecipient.details.bankName,
            accountNumber: savedRecipient.details.accountNumber
        )
    }

    static func make(
        recipient: String?,
        bankName: String?,
        accountNumber: String?
    ) -> [TransferSuccessStatusView.Detail] {
        [
            detail(id: .recipient, title: Constants.recipientTitle, value: recipient),
            detail(id: .bankName, title: Constants.bankNameTitle, value: bankName),
            detail(id: .accountNumber, title: Constants.accountNumberTitle, value: accountNumber),
        ]
        .compactMap { $0 }
    }

    static func detail(
        id: TransferSuccessStatusView.Detail.ID,
        title: String,
        value: String?
    ) -> TransferSuccessStatusView.Detail? {
        guard let value = value?.trimmed().nilIfEmpty else {
            return nil
        }

        return TransferSuccessStatusView.Detail(id: id, title: title, value: value)
    }

    static func recipientName(for name: TangemPayOfframpPersonalDetails.Name) -> String {
        switch name {
        case .individual(let firstName, let lastName):
            [firstName, lastName]
                .compactMap { $0.trimmed().nilIfEmpty }
                .joined(separator: " ")
        case .business(let businessName):
            businessName
        }
    }
}

// MARK: - Constants

private extension TransferSuccessStatusModelBuilder {
    enum Constants {
        static let titlePrefix = "Sending"
        static let recipientTitle = "Recipient"
        static let bankNameTitle = "Bank name"
        static let accountNumberTitle = "Account number"
    }
}
