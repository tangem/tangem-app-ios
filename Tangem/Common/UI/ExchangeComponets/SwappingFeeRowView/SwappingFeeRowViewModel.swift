//
//  SwappingFeeRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct SwappingFeeRowViewModel: Identifiable, Hashable {
    var id: Int { hashValue }

    let fee: String

    init(fee: String) {
        self.fee = fee
    }
}
