//
//  RingUtil.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct RingUtil {
    func isRing(batchId: String) -> Bool {
        batchId.starts(with: "BA")
    }
}
