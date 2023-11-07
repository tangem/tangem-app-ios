//
//  SendFeeSummaryViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

class SendFeeSummaryViewModel: Identifiable {
    let fee: String

    init(fee: String) {
        self.fee = fee
    }
}
