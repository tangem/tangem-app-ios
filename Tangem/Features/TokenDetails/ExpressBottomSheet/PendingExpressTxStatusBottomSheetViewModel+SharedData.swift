//
//  PendingExpressTxStatusBottomSheetViewModel+SharedData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

extension PendingExpressTxStatusBottomSheetViewModel {
    func buildShareText() -> String {
        var lines: [String] = ["tangem", ""]

        switch pendingTransaction.type {
        case .swap(let source, let destination):
            lines.append("\(Localization.commonSend) \(sourceAmountText)")
            if let fromAddress = source.address {
                lines.append("\(Localization.commonFrom): \(fromAddress)")
            }
            lines.append("")
            lines.append("\(Localization.commonReceive) \(destinationAmountText)")
            if let toAddress = destination.address {
                lines.append("\(Localization.commonTo): \(toAddress)")
            }

        case .onramp(_, _, let destination):
            lines.append("\(Localization.commonBuy) \(destinationAmountText)")
            if let toAddress = destination.address {
                lines.append("\(Localization.commonTo): \(toAddress)")
            }
        }

        lines.append("")
        let providerInfo = "\(pendingTransaction.provider.name) \(pendingTransaction.provider.type.rawValue.uppercased())"
        lines.append(Localization.expressByProviderPlaceholder(providerInfo))
        lines.append(Localization.expressTransactionId(pendingTransaction.externalTxId ?? pendingTransaction.expressTransactionId))

        return lines.joined(separator: "\n")
    }
}
