//
//  TransactionDetailsDebugViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG

import Foundation
import UIKit
import TangemUI

struct TransactionDetailsDebugInfo: Equatable {
    let summary: [SummaryRow]
    let dump: String

    struct SummaryRow: Identifiable, Equatable {
        let title: String
        let value: String

        var id: String { title }
    }
}

final class TransactionDetailsDebugViewModel: ObservableObject {
    let info: TransactionDetailsDebugInfo

    var onClose: (() -> Void)?

    init(info: TransactionDetailsDebugInfo) {
        self.info = info
    }

    var summary: [TransactionDetailsDebugInfo.SummaryRow] { info.summary }
    var dumpText: String { info.dump }

    func closeTapped() {
        onClose?()
    }

    func copyTapped() {
        UIPasteboard.general.string = copyText
        Toast(view: SuccessToast(text: "Copied")).present(layout: .top(padding: 14), type: .temporary())
    }

    private var copyText: String {
        let summaryLines = info.summary.map { "\($0.title): \($0.value)" }
        return (summaryLines + ["", info.dump]).joined(separator: "\n")
    }
}

#endif
