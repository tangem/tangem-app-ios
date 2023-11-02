//
//  SendApp.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
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
