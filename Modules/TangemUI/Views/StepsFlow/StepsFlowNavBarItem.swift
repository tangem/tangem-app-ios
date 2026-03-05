//
//  StepsFlowNavBarItem.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct StepsFlowNavBarItem: Equatable {
    @ViewBuilder let content: () -> AnyView

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    private let id = UUID()

    init(content: @escaping () -> some View) {
        self.content = { AnyView(content()) }
    }
}
