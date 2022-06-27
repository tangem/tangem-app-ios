//
//  ChatViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import ZendeskCoreSDK
import SupportSDK
import SwiftUI

class SupportChatViewModel {
    func chatView() -> some View {
        return SupportChatView()
            .edgesIgnoringSafeArea(.vertical)
    }
}
