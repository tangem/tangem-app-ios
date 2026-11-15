//
//  TangemPayMoneyAccountPreviewData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if DEBUG
import Foundation

enum TangemPayMoneyAccountPreviewData {
    static let menuSections: [[TangemPayMoneyAccountMenuItem]] = [
        [.termsAndFees, .support],
        [.closeAccount],
    ]

    static let transactions = [
        TransactionListItem(
            header: "Today",
            items: [
                transaction(
                    interactionAddress: .custom(message: "To: John Smit"),
                    amount: "-$390.00",
                    isOutgoing: true,
                    type: .transfer,
                    status: .inProgress
                ),
                transaction(
                    interactionAddress: .user("33BdfS...ga2B"),
                    amount: "-$10.50",
                    isOutgoing: true,
                    type: .transfer,
                    status: .confirmed
                ),
                transaction(
                    interactionAddress: .user("33BdfS...ga2B"),
                    amount: "+$490.50",
                    isOutgoing: false,
                    type: .swap,
                    status: .confirmed
                ),
                transaction(
                    interactionAddress: .user("33BdfS...ga2B"),
                    amount: "+$490.50",
                    isOutgoing: false,
                    type: .swap,
                    status: .failed
                ),
                transaction(
                    interactionAddress: .user("33BdfS...ga2B"),
                    amount: "+$120.31",
                    isOutgoing: false,
                    type: .transfer,
                    status: .confirmed
                ),
            ]
        ),
    ]

    static let sessionExpiredBannerItems = MultiWalletNotificationBannerMapper().mapItems(
        [
            NotificationsFactory().buildNotificationInput(
                for: TangemPayNotificationEvent.sessionExpired(icon: nil, isRenewing: false),
                buttonAction: { _, _ in }
            ),
        ]
    )

    private static func transaction(
        interactionAddress: TransactionViewModel.InteractionAddressType,
        amount: String,
        isOutgoing: Bool,
        type: TransactionViewModel.TransactionType,
        status: TransactionViewModel.Status
    ) -> TransactionViewModel {
        TransactionViewModel(
            hash: UUID().uuidString,
            index: 0,
            interactionAddress: interactionAddress,
            timeFormatted: "10:45",
            amount: amount,
            value: amount,
            currencyCode: "",
            isOutgoing: isOutgoing,
            transactionType: type,
            status: status,
            isFromYieldContract: false,
            isTangemPayCounterparty: false
        )
    }
}
#endif // DEBUG
