//
//  PolymarketFastTradingToast.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

enum PolymarketFastTradingToast {
    @MainActor
    static func showProgress(_ message: String) {
        present(TangemSnackbar(title: message)
            .icon(DesignSystem.Icons.Info.regular20)
            .iconColor(DesignSystem.Color.iconStatusInfo))
    }

    @MainActor
    static func showFailure(_ failure: PolymarketFastTradingFailure) {
        present(TangemSnackbar(title: failure.message)
            .icon(DesignSystem.Icons.Error.regular20)
            .iconColor(DesignSystem.Color.iconStatusError))
    }

    @MainActor
    private static func present(_ snackbar: TangemSnackbar) {
        Toast(view: snackbar).present(layout: .top(padding: Constants.topPadding), type: .temporary())
    }

    private enum Constants {
        static let topPadding: CGFloat = 8
    }
}
