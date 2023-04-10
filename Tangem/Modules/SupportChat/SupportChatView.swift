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
        switch viewModel.viewState {
        case .webView(let url):
            WebView(url: url)
        case .zendesk(let zendeskViewModel):
            ZendeskSupportChatView(viewModel: zendeskViewModel)
                .actionSheet(isPresented: zendeskViewModel.showingUserActionMenu) {
                    return ActionSheet(title: Text(""), buttons: [])
                }
        case .none:
            EmptyView()
        }
    }
}
