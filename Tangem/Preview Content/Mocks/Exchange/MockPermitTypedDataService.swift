//
//  MockPermitTypedDataService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemExchange

struct MockPermitTypedDataService: PermitTypedDataService {
    func buildPermitCallData(for currency: Currency, parameters: PermitParameters) async throws -> String { "" }
}
