//
//  Error+.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

extension Error {
    func toTaskError() -> SessionError {
        return SessionError.parse(self)
    }
}
