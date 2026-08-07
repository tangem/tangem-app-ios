//
//  TangemPayNetworkRowViewData.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization

struct TangemPayNetworkRowViewData: Identifiable, Equatable {
    let row: TangemPayNetworkRow
    let state: State

    var id: Int { row.id }

    var isTappable: Bool {
        row.action != nil && state != .loading
    }

    var subtitle: String {
        switch state {
        case .idle: row.subtitle
        case .loading: Localization.tangempayChooseNetworkRowLoading
        case .error: Localization.tangempayChooseNetworkRowError
        }
    }

    var subtitleColor: Color? {
        switch state {
        case .idle, .loading: nil
        case .error: DesignSystem.Color.textStatusError
        }
    }

    enum State {
        case idle
        case loading
        case error
    }
}
