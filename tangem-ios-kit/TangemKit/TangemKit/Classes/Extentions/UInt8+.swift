//
//  UInt8+.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

extension UInt8 {
    var asData: Data {
        Data([self])
    }
}
