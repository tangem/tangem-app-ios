//
//  SendDestinationViewModel.swift
//  Send
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import SwiftUI

class SendDestinationViewModel {
    var destination: Binding<String>

    init(destination: Binding<String>) {
        self.destination = destination
    }
}
