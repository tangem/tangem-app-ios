//
//  AppAssertion.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

package import struct Foundation.Data

/// Demonstration of the legitimacy that Tangem app is running on a real apple device.
package struct AppAssertion: Equatable, Sendable {
    package let keyID: String
    package let object: Data
}
