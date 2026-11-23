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
    static func showInfo(_ message: String) {
        present(info(message))
    }

    @MainActor
    static func showRevocation(_ revocation: PolymarketFastTradingRevocation) {
        let snackbar = switch revocation {
        case .submitted:
            info(PolymarketFastTradingStrings.revocationInProgress)
        case .succeeded:
            success(PolymarketFastTradingStrings.revocationSucceeded)
        case .failed:
            error(PolymarketFastTradingStrings.revocationFailed)
        }

        present(snackbar)
    }

    @MainActor
    static func showFailure(_ failure: PolymarketFastTradingFailure) {
        present(error(failure.message))
    }
}

// MARK: - Private

private extension PolymarketFastTradingToast {
    static func info(_ message: String) -> TangemSnackbar {
        TangemSnackbar(title: message)
            .icon(DesignSystem.Icons.Info.regular20)
            .iconColor(DesignSystem.Color.iconStatusInfo)
    }

    static func success(_ message: String) -> TangemSnackbar {
        TangemSnackbar(title: message)
            .icon(DesignSystem.Icons.Success.regular20)
            .iconColor(DesignSystem.Color.iconStatusSuccess)
    }

    static func error(_ message: String) -> TangemSnackbar {
        TangemSnackbar(title: message)
            .icon(DesignSystem.Icons.Error.regular20)
            .iconColor(DesignSystem.Color.iconStatusError)
    }

    @MainActor
    static func present(_ snackbar: TangemSnackbar) {
        Toast(view: snackbar).present(layout: .top(padding: Constants.topPadding), type: .temporary())
    }

    enum Constants {
        static let topPadding: CGFloat = 8
    }
}
