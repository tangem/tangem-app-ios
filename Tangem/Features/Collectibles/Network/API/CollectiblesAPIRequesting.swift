//
//  CollectiblesAPIRequesting.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol CollectiblesAPIRequesting {
    func request<T: Decodable>(_ target: CollectiblesAPITarget.Target) async throws -> T
}
