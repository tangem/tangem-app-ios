//
//  AppAssertion+fake.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@testable import TangemBackendAuthentication

extension AppAssertion {
    static let fake = AppAssertion(keyID: "any-app-assert-key", object: Data("any-app-assert-object".utf8))
}
