//
//  SendFeeViewModel.swift
//  Send
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import SwiftUI

class SendFeeViewModel {
    var fee: Binding<String>

    init(fee: Binding<String>) {
        self.fee = fee
    }
}
