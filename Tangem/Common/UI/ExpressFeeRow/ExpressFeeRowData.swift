//
//  ExpressFeeRowData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct ExpressFeeRowData: Identifiable {
    var id: String { title }

    let title: String
    let subtitle: String
    let action: () -> Void
}
