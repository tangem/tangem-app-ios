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

protocol BalancesViewModel: ObservableObject {
    var cryptoBalance: LoadableTokenBalanceView.State { get set }
    var fiatBalance: LoadableTokenBalanceView.State { get set }

    var balanceAccessibilityIdentifier: String? { get }
    var isYieldActive: Bool { get }

    var isRefreshing: Bool { get }
}
