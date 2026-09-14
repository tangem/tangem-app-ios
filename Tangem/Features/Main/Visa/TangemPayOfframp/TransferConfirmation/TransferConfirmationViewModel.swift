//
//  TransferConfirmationViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemPay

@MainActor
final class TransferConfirmationViewModel: ObservableObject {
    @Published private(set) var contentState: TransferConfirmationContentView.State

    let title: String

    private let orderBuilder: TangemPayOfframpOrderBuilder
    private let tokenItems: [TransferInputTokenItem]
    private let railItems: [TransferInputRailItem]
    private let savedRecipient: TangemPayBankAccountResponse?
    private let sendButtonIcon: ImageType?
    private let output: (Output) -> Void

    init(
        orderBuilder: TangemPayOfframpOrderBuilder,
        tokenItems: [TransferInputTokenItem],
        railItems: [TransferInputRailItem],
        savedRecipient: TangemPayBankAccountResponse?,
        title: String,
        sendButtonIcon: ImageType?,
        output: @escaping (Output) -> Void
    ) {
        self.orderBuilder = orderBuilder
        self.tokenItems = tokenItems
        self.railItems = railItems
        self.savedRecipient = savedRecipient
        self.title = title
        self.sendButtonIcon = sendButtonIcon
        self.output = output

        if orderBuilder.rail == nil, let rail = railItems.first?.rail {
            orderBuilder.set(rail: rail)
        }

        contentState = Self.makeContentState(
            orderBuilder: orderBuilder,
            tokenItems: tokenItems,
            railItems: railItems,
            savedRecipient: savedRecipient,
            sendButtonIcon: sendButtonIcon
        )
    }

    func refresh() {
        contentState = Self.makeContentState(
            orderBuilder: orderBuilder,
            tokenItems: tokenItems,
            railItems: railItems,
            savedRecipient: savedRecipient,
            sendButtonIcon: sendButtonIcon
        )
    }

    func handle(_ action: TransferConfirmationContentView.Action) {
        switch action {
        case .editTap(let target):
            output(.edit(target))

        case .sendTap:
            break
        }
    }

    func onCloseTap() {
        output(.close)
    }
}

// MARK: - Content state

private extension TransferConfirmationViewModel {
    static func makeContentState(
        orderBuilder: TangemPayOfframpOrderBuilder,
        tokenItems: [TransferInputTokenItem],
        railItems: [TransferInputRailItem],
        savedRecipient: TangemPayBankAccountResponse?,
        sendButtonIcon: ImageType?
    ) -> TransferConfirmationContentView.State {
        let token = selectedToken(orderBuilder: orderBuilder, tokenItems: tokenItems)
        let rail = railItems.first { $0.rail == orderBuilder.rail }

        return TransferConfirmationContentView.State(
            balanceText: token?.balanceText ?? "",
            amountText: orderBuilder.amount.map(format) ?? "",
            token: token,
            rail: rail,
            sections: sections(orderBuilder: orderBuilder, savedRecipient: savedRecipient),
            footerNote: footerNote(amount: orderBuilder.amount, rail: rail),
            sendButtonIcon: sendButtonIcon,
            isSendEnabled: orderBuilder.amount != nil && token != nil && rail != nil
        )
    }

    static func selectedToken(
        orderBuilder: TangemPayOfframpOrderBuilder,
        tokenItems: [TransferInputTokenItem]
    ) -> TransferInputTokenItem? {
        guard let token = orderBuilder.token else { return nil }

        let id = TangemPayOfframpOptionsStore.tokenID(
            chainId: token.chainId,
            contractAddress: token.tokenContractAddress
        )

        return tokenItems.first { $0.id == id }
    }

    static func sections(
        orderBuilder: TangemPayOfframpOrderBuilder,
        savedRecipient: TangemPayBankAccountResponse?
    ) -> [TransferConfirmationSection] {
        if let savedRecipient {
            return TransferConfirmationSectionsBuilder.sections(savedRecipient: savedRecipient)
        }

        return TransferConfirmationSectionsBuilder.sections(
            personalDetails: orderBuilder.personalDetails,
            bankDetails: orderBuilder.bankDetails
        )
    }

    static func footerNote(amount: Decimal?, rail: TransferInputRailItem?) -> String? {
        guard let amount, let rail else {
            return nil
        }

        // [REDACTED_TODO_COMMENT]
        return "You are sending \(format(amount + rail.feeAmount)) including a \(rail.title) fee of \(rail.feeText)"
    }

    static func format(_ amount: Decimal) -> String {
        BalanceFormatter().formatFiatBalance(
            amount,
            currencyCode: TangemPayUtilities.fiatItem.currencyCode,
            formattingOptions: Constants.amountFormattingOptions
        )
    }
}

// MARK: - Output

extension TransferConfirmationViewModel {
    enum Output {
        case edit(TransferConfirmationEditTarget)
        case close
    }
}

// MARK: - Constants

private extension TransferConfirmationViewModel {
    enum Constants {
        static let fractionDigits = 2

        static let amountFormattingOptions = BalanceFormattingOptions(
            minFractionDigits: 0,
            maxFractionDigits: fractionDigits,
            formatEpsilonAsLowestRepresentableValue: false,
            roundingType: .default(roundingMode: .plain, scale: fractionDigits)
        )
    }
}
