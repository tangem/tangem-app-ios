//
//  ExpressLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemLogger

public let ExpressLogger = Logger(category: OSLogCategory(name: "Express"))
public let OnrampLogger = ExpressLogger.tag("Onramp")
public let TransactionHistoryLogger = ExpressLogger.tag("TransactionHistory")
