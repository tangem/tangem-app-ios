//
//  OnboardingAddTokensDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import struct TangemUIUtils.AlertBinder

protocol OnboardingAddTokensDelegate: AnyObject {
    func goToNextStep()
    func showAlert(_ alert: AlertBinder)
}
