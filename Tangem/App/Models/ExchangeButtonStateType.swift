//
//  ExchangeButtonType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// Type of main button view
enum ExchangeButtonStateType: Hashable, CaseIterable {
    case buy
    case sell
    case swap

    var title: String {
        switch self {
        case .buy:
            return Localization.walletButtonBuy
        case .sell:
            return Localization.walletButtonSell
        case .swap:
            return Localization.swappingSwap
        }
    }

    var icon: ImageType {
        switch self {
        case .buy:
            return Assets.arrowUpMini
        case .sell:
            return Assets.arrowDownMini
        case .swap:
            return Assets.exchangeIcon
        }
    }
}

/// State of main button view
enum ExchangeButtonState: Hashable {
    case single(option: ExchangeButtonType)
    case multi(options: [ExchangeButtonType])

    var options: [ExchangeButtonType] {
        switch self {
        case .single(let option):
            return [option]
        case .multi(let options):
            return options
        }
    }

    init(options: [ExchangeButtonType]) {
        if options.count == 1, let option = options.first {
            self = .single(option: option)
        } else {
            self = .multi(options: options)
        }
    }
}
