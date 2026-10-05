//
//  CollectiblesMachineRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
protocol CollectiblesMachineRoutable: AnyObject {
    func openConfirmOrder(machineID: String, machine: CollectiblesMachine, isTurboModeOn: Bool)
}
