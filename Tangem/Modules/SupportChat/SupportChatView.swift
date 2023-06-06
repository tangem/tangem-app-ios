//
//  ChatView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SupportChatView: View {
    @ObservedObject var viewModel: SupportChatViewModel

    var body: some View {
        if let zendeskViewModel = viewModel.zendeskViewModel {
            ZendeskSupportChatView(viewModel: zendeskViewModel)
                .actionSheet(item: $viewModel.showSupportActionSheet, content: { $0.sheet })
        }
    }
}
