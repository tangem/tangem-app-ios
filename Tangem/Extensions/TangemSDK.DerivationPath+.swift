//
//  TangemSDK.DerivationPath+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

extension DerivationPath {
    static var canonicalLength: Int {
        5
    }

    var isCanonical: Bool {
        nodes.count == Self.canonicalLength
    }
}
