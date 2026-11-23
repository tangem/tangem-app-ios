//
//  String+DroppingNetworkSuffix.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension String {
    var droppingNetworkSuffix: String {
        replacingOccurrences(of: #"\s+network(?=(\s+testnet)?$)"#, with: "", options: [.regularExpression, .caseInsensitive])
    }
}
