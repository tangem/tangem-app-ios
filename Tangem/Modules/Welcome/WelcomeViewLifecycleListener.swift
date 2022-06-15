//
//  WelcomeViewLifecycleListener.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol WelcomeViewLifecycleListener: AnyObject {
    func resignActve()
    func becomeActive()
}
