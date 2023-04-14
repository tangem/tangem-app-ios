//
//  SwappingManagerDelegate.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public protocol SwappingManagerDelegate: AnyObject {
    func swappingManager(_ manager: SwappingManager, didUpdate swappingItems: SwappingItems)
    func swappingManager(_ manager: SwappingManager, didUpdate availabilityState: SwappingAvailabilityState)
}
