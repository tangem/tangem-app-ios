//
//  RefundInfo.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct RefundInfo: Hashable {
    public let address: String
    public let extraId: String?
    public let currency: ExpressCurrency?
}
