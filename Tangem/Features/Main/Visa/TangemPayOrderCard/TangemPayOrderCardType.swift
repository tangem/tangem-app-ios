//
//  TangemPayOrderCardType.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization
import TangemUI

enum TangemPayOrderCardType: TabNavigationItem, CaseIterable {
    case virtual
    case plastic

    var id: Self { self }

    var title: String {
        switch self {
        case .virtual: Localization.tangempayOrderTypeSegmentVirtual
        case .plastic: Localization.tangempayOrderTypeSegmentPlastic
        }
    }

    var counter: String? {
        switch self {
        case .virtual: nil
        case .plastic: Localization.tangempayOrderTypeBeta
        }
    }
}
