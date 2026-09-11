//
//  AccountsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemLogger
import Foundation

let AccountsLogger = Logger(category: OSLogCategory(name: "Accounts"))
let JointAccountsLogger = AccountsLogger.tag("Joint")
