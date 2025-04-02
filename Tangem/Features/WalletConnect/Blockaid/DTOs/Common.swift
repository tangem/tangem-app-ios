//
//  Common.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension BlockaidDTO {
    enum ResultType: String, Decodable {
        case malicious = "Malicious"
        case warning = "Warning"
        case benign = "Benign"
        case info = "Info"
    }
    
    enum Status: String, Decodable {
        case success = "Success"
        case error = "Error"
    }
}
