//
//  File.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

struct StepsFlowRoute {
    private var id: AnyHashable { step.id }

    let step: any StepsFlowStep

    init(step: any StepsFlowStep) {
        self.step = step
    }
}

extension StepsFlowRoute: NavigationRoutable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
