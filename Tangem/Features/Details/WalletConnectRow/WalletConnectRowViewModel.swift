//
//  WalletConnectRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct WalletConnectRowViewModel: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let action: () -> Void

    init(title: String, subtitle: String, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }
}
