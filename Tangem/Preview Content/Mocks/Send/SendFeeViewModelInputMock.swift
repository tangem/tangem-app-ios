//
//  SendFeeViewModelInputMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

class SendFeeViewModelInputMock: SendFeeViewModelInput {
    var feeTextBinding: Binding<String> { .constant("Fee") }
}
