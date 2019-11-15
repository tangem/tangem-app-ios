//
//  Date+.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

extension Date {
    public func toString(style: DateFormatter.Style = .medium) -> String {
        let manFormatter = DateFormatter()
        manFormatter.dateStyle = style
        return manFormatter.string(from: self)
    }
}
