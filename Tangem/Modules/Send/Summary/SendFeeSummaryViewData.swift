//
//  SendFeeSummaryViewData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SendFeeSummaryViewData: Identifiable {
    let id = UUID()

    let title: String
    let cryptoAmount: String
    let fiatAmount: String?

    var feeName: String {
        feeOption.title
    }

    var feeIconImage: Image {
        feeOption.icon.image
    }

    private let feeOption: FeeOption

    init(title: String, feeOption: FeeOption, cryptoAmount: String, fiatAmount: String?) {
        self.title = title
        self.feeOption = feeOption
        self.cryptoAmount = cryptoAmount
        self.fiatAmount = fiatAmount
    }
}
