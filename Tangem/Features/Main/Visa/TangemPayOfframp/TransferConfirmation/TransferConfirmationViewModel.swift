//
//  TransferConfirmationViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemLocalization
import TangemPay
import TangemVisa

@MainActor
final class TransferConfirmationViewModel: ObservableObject {
    @Published private(set) var contentState: TransferConfirmationContentView.State
    @Published private(set) var isSending = false

    let title: String

    private let orderBuilder: TangemPayOfframpOrderBuilder
    private let sendUseCase: TangemPayOffRampSendUseCase
    private let options: TangemPayOfframpOptionsStore.Options
    private let savedRecipient: TangemPayBankAccountResponse?
    private let sendButtonIcon: ImageType?
    private let analyticsLogger: any TangemPayOfframpAnalyticsLogger
    private let output: (Output) -> Void

    init(
        orderBuilder: TangemPayOfframpOrderBuilder,
        sendUseCase: TangemPayOffRampSendUseCase,
        options: TangemPayOfframpOptionsStore.Options,
        savedRecipient: TangemPayBankAccountResponse?,
        title: String,
        sendButtonIcon: ImageType?,
        analyticsLogger: any TangemPayOfframpAnalyticsLogger,
        output: @escaping (Output) -> Void
    ) {
        self.orderBuilder = orderBuilder
        self.sendUseCase = sendUseCase
        self.options = options
        self.savedRecipient = savedRecipient
        self.title = title
        self.sendButtonIcon = sendButtonIcon
        self.analyticsLogger = analyticsLogger
        self.output = output

        if orderBuilder.rail == nil, let rail = options.defaultRail?.rail {
            orderBuilder.set(rail: rail)
        }

        contentState = Self.makeContentState(
            orderBuilder: orderBuilder,
            options: options,
            savedRecipient: savedRecipient,
            sendButtonIcon: sendButtonIcon,
            isSending: false
        )

        analyticsLogger.logConfirmationScreenOpened()
    }

    func refresh() {
        contentState = Self.makeContentState(
            orderBuilder: orderBuilder,
            options: options,
            savedRecipient: savedRecipient,
            sendButtonIcon: sendButtonIcon,
            isSending: isSending
        )
    }

    func handle(_ action: TransferConfirmationContentView.Action) {
        guard !isSending else {
            return
        }

        switch action {
        case .editTap(let target):
            logEditClicked(target)
            output(.edit(target))

        case .railTap:
            guard !orderBuilder.isRailLocked else { return }

            analyticsLogger.logRailSelectorClicked()
            output(.edit(.amount))

        case .sendTap:
            analyticsLogger.logSendOnConfirmationClicked()
            send()
        }
    }

    func onCloseTap() {
        output(.close)
    }
}

// MARK: - Edit analytics

private extension TransferConfirmationViewModel {
    func logEditClicked(_ target: TransferConfirmationEditTarget) {
        switch target {
        case .amount:
            break
        case .personalDetails:
            analyticsLogger.logRecipientDetailsOnConfirmationClicked()
        case .bankDetails:
            analyticsLogger.logRecipientBankDetailsOnConfirmationClicked()
        }
    }
}

// MARK: - Sending

private extension TransferConfirmationViewModel {
    func send() {
        let request: TangemPayPlaceOrderRequest

        do {
            request = try orderBuilder.buildOrderRequest()
        } catch {
            VisaLogger.error("Failed to build Tangem Pay off-ramp order request", error: error)
            handle(.generic)
            return
        }

        perform { [sendUseCase] in
            try await sendUseCase.send(request: request)
        }
    }

    func retry() {
        perform { [sendUseCase] in
            try await sendUseCase.retry()
        }
    }

    func retrySignature() {
        perform { [sendUseCase] in
            try await sendUseCase.retrySignature()
        }
    }

    func perform(_ operation: @escaping () async throws -> TangemPayOffRampSendUseCase.SendResult) {
        isSending = true
        refresh()

        Task { [weak self] in
            guard let self else {
                return
            }

            do {
                let result = try await operation()
                analyticsLogger.logSendSuccessScreenShowed(rail: orderBuilder.rail)
                output(.sent(makeSuccessStatusModel(date: result.createdAt)))
            } catch {
                VisaLogger.error("Failed to send the Tangem Pay off-ramp order", error: error)
                handle(error as? TangemPayOffRampSendUseCase.SendError ?? .generic)
            }
        }
    }

    func handle(_ error: TangemPayOffRampSendUseCase.SendError) {
        switch error {
        case .cancelled:
            isSending = false
            refresh()

        case .retryable:
            analyticsLogger.logSendErrorScreenOpened()
            output(.failed(
                model: TransferFailedStatusModelMapper.model(for: error),
                onRetry: { [weak self] in self?.retry() },
                onClose: { [sendUseCase] in
                    Task { await sendUseCase.abandonRetry() }
                }
            ))

        case .signatureSubmission(canRetry: true):
            analyticsLogger.logSendErrorScreenOpened()
            output(.failed(
                model: TransferFailedStatusModelMapper.model(for: error),
                onRetry: { [weak self] in self?.retrySignature() },
                onClose: nil
            ))

        case .unavailableRegion, .generic, .signatureSubmission:
            analyticsLogger.logSendErrorScreenOpened()
            output(.failed(model: TransferFailedStatusModelMapper.model(for: error), onRetry: nil, onClose: nil))
        }
    }

    func makeSuccessStatusModel(date: Date) -> TransferSuccessStatusView.Model {
        TransferSuccessStatusModelBuilder.model(
            amount: orderBuilder.amount,
            date: date,
            personalDetails: orderBuilder.personalDetails,
            bankDetails: orderBuilder.bankDetails,
            savedRecipient: savedRecipient
        )
    }
}

// MARK: - Content state

private extension TransferConfirmationViewModel {
    static func makeContentState(
        orderBuilder: TangemPayOfframpOrderBuilder,
        options: TangemPayOfframpOptionsStore.Options,
        savedRecipient: TangemPayBankAccountResponse?,
        sendButtonIcon: ImageType?,
        isSending: Bool
    ) -> TransferConfirmationContentView.State {
        let token = selectedToken(orderBuilder: orderBuilder, tokenItems: options.tokens)
        let rail = options.rail(preferring: orderBuilder.rail)

        return TransferConfirmationContentView.State(
            balanceText: token?.balanceText ?? "",
            amountText: orderBuilder.amount.map { TangemPayOfframpAmountFormatter.format($0) } ?? "",
            token: token,
            rail: rail,
            isRailSelectable: !orderBuilder.isRailLocked,
            sections: sections(orderBuilder: orderBuilder, savedRecipient: savedRecipient),
            footerNote: footerNote(amount: orderBuilder.amount, rail: rail),
            sendButtonIcon: sendButtonIcon,
            isSendEnabled: orderBuilder.amount != nil && token != nil && rail != nil,
            isSending: isSending
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

        let total = TangemPayOfframpAmountFormatter.format(amount + rail.feeAmount)

        return Localization.tangempayWithdrawBankSendingSummary(total, rail.title, rail.feeText)
    }
}

// MARK: - Output

extension TransferConfirmationViewModel {
    enum Output {
        case edit(TransferConfirmationEditTarget)
        case sent(TransferSuccessStatusView.Model)
        case failed(model: TransferFailedStatusView.Model, onRetry: (() -> Void)?, onClose: (() -> Void)?)
        case close
    }
}
