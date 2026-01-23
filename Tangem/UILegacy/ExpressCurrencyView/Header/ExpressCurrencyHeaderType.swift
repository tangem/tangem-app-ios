//
//  ExpressCurrencyHeaderType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import struct TangemAccounts.AccountIconView

enum ExpressCurrencyHeaderType: Hashable {
    case action(name: String)
    case wallet(name: String)
    case account(prefix: String, name: String, icon: AccountIconView.ViewData)
}

// MARK: - Convenience extensions

extension ExpressCurrencyHeaderType {
    init(viewType: ExpressCurrencyViewType, tokenHeader: ExpressInteractorTokenHeader?) {
        switch tokenHeader {
        case .none:
            self = .action(name: viewType.actionName())
        case .wallet(let name):
            self = .wallet(name: viewType.prefix(wallet: name))
        case .account(let name, let icon):
            self = .account(prefix: viewType.prefix(), name: name, icon: icon)
        }
    }
}
