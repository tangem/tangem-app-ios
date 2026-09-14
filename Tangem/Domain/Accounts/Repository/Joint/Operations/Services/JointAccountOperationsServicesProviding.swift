//
//  JointAccountOperationsServicesProviding.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// What a joint account hands out for operating it: the service its operations go through, and the unfinished ones.
protocol JointAccountOperationsServicesProviding {
    var jointAccountOperationsService: JointAccountOperationsService { get }
    var jointAccountPendingOperationsProvider: JointAccountPendingOperationsProvider { get }
}
