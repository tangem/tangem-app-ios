//
//  SupportChatViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class SupportChatViewModel: ObservableObject, Identifiable {
//    [REDACTED_USERNAME] var sprinklrViewModel = SprinklrSupportChatViewModel()
    private let input: SupportChatInputModel

    init(input: SupportChatInputModel) {
        self.input = input
    }
}
