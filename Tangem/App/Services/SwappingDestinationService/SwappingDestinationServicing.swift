//
//  SwappingDestinationServicing.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemSwapping

protocol SwappingDestinationServicing {
    func getDestination(source: Currency) async throws -> Currency
}
