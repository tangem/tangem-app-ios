//
//  HotOnboardingFlowNavBarAction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum HotOnboardingFlowNavBarAction {
    case back(handler: () -> Void)
    case close(handler: () -> Void)
}
