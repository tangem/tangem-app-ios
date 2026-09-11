//
//  CollectiblesMachineProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol CollectiblesMachineProvider {
    func load(id: String) async throws -> CollectiblesMachine
}
