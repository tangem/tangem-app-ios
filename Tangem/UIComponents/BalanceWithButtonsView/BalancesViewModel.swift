//
//  BalancesViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemAccessibilityIdentifiers
import TangemUI

protocol BalancesViewModel: ObservableObject {
    var cryptoBalance: LoadableBalanceView.State { get set }
    var fiatBalance: LoadableBalanceView.State { get set }

    var balanceAccessibilityIdentifier: String? { get }
    var isYieldActive: Bool { get }

    var isRefreshing: Bool { get }
}
