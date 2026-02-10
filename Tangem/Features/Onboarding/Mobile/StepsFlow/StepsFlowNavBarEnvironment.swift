//
//  StepsFlowNavBarEnvironment.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

final class StepsFlowNavBarEnvironment: ObservableObject {
    @Published var title: String?
    @Published var leadingItem: StepsFlowNavBarItem?
    @Published var trailingItem: StepsFlowNavBarItem?
}
