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
        present(info(message), placement: .top)
    }

    @MainActor
    static func showInfoBelowNavigationBar(_ message: String) {
        present(info(message), placement: .belowNavigationBar)
    }

    @MainActor
    static func showFailure(_ failure: PolymarketFastTradingFailure) {
        present(
            TangemSnackbar(title: failure.message)
                .icon(DesignSystem.Icons.Error.regular20)
                .iconColor(DesignSystem.Color.iconStatusError),
            placement: .top
        )
    }
}

// MARK: - Private

private extension PolymarketFastTradingToast {
    enum Placement {
        case top
        case belowNavigationBar

        var padding: CGFloat {
            switch self {
            case .top:
                Constants.topPadding
            case .belowNavigationBar:
                Constants.navigationBarHeight + Constants.belowNavigationBarPadding
            }
        }
    }

    static func info(_ message: String) -> TangemSnackbar {
        TangemSnackbar(title: message)
            .icon(DesignSystem.Icons.Info.regular20)
            .iconColor(DesignSystem.Color.iconStatusInfo)
    }

    @MainActor
    static func present(_ snackbar: TangemSnackbar, placement: Placement) {
        Toast(view: snackbar).present(layout: .top(padding: placement.padding), type: .temporary())
    }

    enum Constants {
        static let topPadding: CGFloat = 8
        static let navigationBarHeight: CGFloat = 44
        static let belowNavigationBarPadding: CGFloat = 24
    }
}
