//
//  ExpressShareTextBuilder.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization

enum ExpressShareTextBuilder {
    enum Operation {
        case swap(send: String, from: String?, receive: String, to: String?)
        case onramp(send: String, receive: String, to: String?)
    }

    static func build(operation: Operation, providerInfo: String?, transactionId: String, onChainHash: String?) -> String {
        var lines = [Localization.commonTangem, ""]

        switch operation {
        case .swap(let send, let from, let receive, let to):
            lines.append("\(Localization.commonSend) \(send)")
            if let from {
                lines.append("\(Localization.commonFrom): \(from)")
            }
            lines.append("")
            lines.append("\(Localization.commonReceive) \(receive)")
            if let to {
                lines.append("\(Localization.commonTo): \(to)")
            }

        case .onramp(let send, let receive, let to):
            lines.append("\(Localization.commonSend) \(send)")
            lines.append("")
            lines.append("\(Localization.commonReceive) \(receive)")
            if let to {
                lines.append("\(Localization.commonTo): \(to)")
            }
        }

        lines.append("")

        if let providerInfo {
            lines.append(Localization.expressByProviderPlaceholder(providerInfo))
        }

        lines.append(Localization.expressTransactionId(transactionId))

        if let onChainHash {
            lines.append(Localization.expressTransactionHash(onChainHash))
        }

        return lines.joined(separator: "\n")
    }
}
