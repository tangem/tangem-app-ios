//
//  WCToastFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

final class WCToastFactory {
    func makeWarningToast(with text: String) {
        Toast(view: WarningToast(text: text))
            .present(
                layout: .top(padding: 20),
                type: .temporary()
            )
    }

    func makeSuccessToast(with text: String) {
        Toast(view: SuccessToast(text: text))
            .present(
                layout: .top(padding: 20),
                type: .temporary()
            )
    }
}
