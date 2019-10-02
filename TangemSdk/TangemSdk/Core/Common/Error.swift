//
//  Error.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public enum ApduError: String, Error {
    case invalidLength = "Response length must be greater then 2"
}
