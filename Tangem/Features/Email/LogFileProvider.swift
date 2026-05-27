//
//  LogFileProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemLogger

protocol LogFileProvider {
    var logData: Data? { get }
}
