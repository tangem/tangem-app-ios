//
//  ShareActivitiesPresenter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import UIKit
import TangemFoundation

@MainActor
protocol ShareActivitiesPresenter {
    func share(activityItems: [Any])
}
