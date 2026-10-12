//
//  UserDefaults+Concurrency.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import class Foundation.UserDefaults

// [REDACTED_USERNAME], UserDefaults is documented as thread-safe. Safe here as long as callers only
// ever pass the base class, not a subclass — Swift can't verify that of arbitrary subclasses.

extension UserDefaults: @retroactive @unchecked Sendable {}
