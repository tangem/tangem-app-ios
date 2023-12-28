//
//  SendFinishViewModelInputMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class SendFinishViewModelInputMock: SendFinishViewModelInput {
    var amountText: String { "100,00" }
    var destinationText: String? { "0x123123123" }
    var feeText: String { "Fee" }
    var transactionTime: Date? { Date() }
    var transactionURL: URL? { URL(string: "google.com")! }
}
