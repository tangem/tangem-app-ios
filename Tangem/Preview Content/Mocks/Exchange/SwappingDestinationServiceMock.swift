//
//  SwappingDestinationServiceMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemExchange

struct SwappingDestinationServiceMock: SwappingDestinationServicing {
    func getDestination(source: Currency) async throws -> Currency {
        .mock
    }
}
