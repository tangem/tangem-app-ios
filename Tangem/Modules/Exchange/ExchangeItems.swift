//
//  ExchangeViewItem.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct ExchangeItems: Identifiable {
    let id: UUID = UUID()

    let fromItem: ExchangeItem
    let toItem: ExchangeItem
}
