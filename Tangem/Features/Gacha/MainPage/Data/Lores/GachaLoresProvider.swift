//
//  GachaLoresProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol GachaLoresProvider {
    func load() async throws -> [GachaLore]
}
