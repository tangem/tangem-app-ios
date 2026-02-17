//
//  MobileUpgradeBannerManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol MobileUpgradeBannerManager {
    var shouldShowPublisher: AnyPublisher<Bool, Never> { get }
    func shouldClose()
}
