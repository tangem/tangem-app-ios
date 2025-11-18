//
//  WCRequestDetailsInput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import UIKit
import TangemUI
import TangemLocalization

struct WCRequestDetailsInput {
    let builder: WCRequestDetailsBuilder
    let rawTransaction: String?
    let simulationResult: BlockaidChainScanResult?
    let backAction: () -> Void

    func copyTransactionData() {
        guard let rawTransaction, rawTransaction.isNotEmpty else { return }

        UIPasteboard.general.string = rawTransaction

        let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
        heavyImpactGenerator.impactOccurred()

        Toast(view: SuccessToast(text: Localization.commonValueCopied))
            .present(
                layout: .top(padding: 20.0),
                type: .temporary()
            )
    }
}

extension WCRequestDetailsInput: Equatable {
    static func == (lhs: WCRequestDetailsInput, rhs: WCRequestDetailsInput) -> Bool {
        lhs.builder == rhs.builder
    }
}
