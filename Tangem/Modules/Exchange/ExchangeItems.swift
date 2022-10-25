//
//  ExchangeViewItem.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct ExchangeItems: Identifiable {
    var id: UUID = UUID()

    let fromItem: ExchangeItem
    let toItem: ExchangeItem
}
