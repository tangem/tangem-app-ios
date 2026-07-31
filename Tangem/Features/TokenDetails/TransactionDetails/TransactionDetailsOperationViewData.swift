//
//  TransactionDetailsOperationViewData.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemExpress

enum TransactionDetailsOperationStage: Hashable {
    case inProgress
    case finished
    case unsuccessful
}

// [REDACTED_TODO_COMMENT]
enum TransactionOperationStatusMapper {
    static func stage(for status: ExpressTransactionStatus) -> TransactionDetailsOperationStage {
        switch status {
        case .finished:
            return .finished
        case .failed, .txFailed, .refunded, .expired:
            return .unsuccessful
        case .unknown, .preview, .created, .exchangeTxSent, .waiting, .waitingTxHash,
             .confirming, .exchanging, .sending, .verifying, .paused:
            return .inProgress
        }
    }

    static func stage(for status: OnrampTransactionStatus) -> TransactionDetailsOperationStage {
        switch status {
        case .finished:
            return .finished
        case .failed, .expired, .refunded:
            return .unsuccessful
        case .unknown, .created, .waitingForPayment, .paymentProcessing, .verifying,
             .paid, .sending, .refunding, .paused:
            return .inProgress
        }
    }

    static func viewStatus(for stage: TransactionDetailsOperationStage) -> TransactionViewModel.Status {
        switch stage {
        case .inProgress:
            return .inProgress
        case .finished:
            return .confirmed
        case .unsuccessful:
            return .failed
        }
    }

    static func viewStatus(for record: TransactionRecord) -> TransactionViewModel.Status {
        switch record.expressExtraInfo {
        case .exchange(let info):
            return viewStatus(for: stage(for: info.transaction.status))
        case .onramp(let info):
            return viewStatus(for: stage(for: info.onrampTransaction.status))
        case nil:
            switch record.status {
            case .confirmed:
                return .confirmed
            case .failed:
                return .failed
            case .unconfirmed:
                return .inProgress
            case .undefined:
                return .undefined
            }
        }
    }
}

protocol TransactionDetailsOperationViewData {
    var tokensData: TransactionDetailsTokensViewData { get }
    var statusBanner: TransactionDetailsStatusBannerViewData? { get }
    var infoData: TransactionDetailsInfoSectionViewData? { get }
    var action: TransactionDetailsActionButtonViewData? { get }
}

extension TransactionDetailsOperationViewData {
    var blocks: [TransactionDetailsBlock] {
        var blocks: [TransactionDetailsBlock] = [.tokens(tokensData)]

        if let statusBanner {
            blocks.append(.statusBanner(statusBanner))
        }

        if let infoData {
            blocks.append(.info(infoData))
        }

        if let action {
            blocks.append(.action(action))
        }

        return blocks
    }
}
