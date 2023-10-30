//
//  SendApp.swift
//  Send
//
//  Created by [REDACTED_AUTHOR]
//

import SwiftUI

@main
struct SendApp: App {
    let viewModel = SendViewModel(coordinator: MockSendRoutable())

    var body: some Scene {
        WindowGroup {
            SendView(viewModel: viewModel)
        }
    }
}
