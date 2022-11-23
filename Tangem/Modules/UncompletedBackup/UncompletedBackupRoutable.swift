//
//  UncompletedBackupRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol UncompletedBackupRoutable: AnyObject {
    func openOnboardingModal(with input: OnboardingInput)
    func dismiss()
}
