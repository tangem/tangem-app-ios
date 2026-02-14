//
//  StepsFlowEnvironment.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

final class StepsFlowEnvironment: ObservableObject {
    @Published var navigationTitle: String?
    @Published var navigationLeadingItem: StepsFlowNavBarItem?
    @Published var navigationTrailingItem: StepsFlowNavBarItem?
    @Published var isLoading: Bool = false
}
