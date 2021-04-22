//
//  CardIdFormatter.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct CardIdFormatter {
    public init() {}
    
    public func crop(cid: String, with length: Int? = nil) -> String {
        length == nil ? cid : String(cid.dropLast().suffix(length!))
    }
    
    public func formatted(cid: String, numbers: Int? = nil) -> String {
        let croppedCid = crop(cid: cid, with: numbers)
        let format = "cid_format".localized
        return String(format: format, croppedCid)
    }
}
