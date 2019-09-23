//
//  EstimateFeeEndpoint.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

public enum EstimateFeeEndpoint: BtcEndpoint {
  
    
    case minimal
    case normal
    case priority
    
    public var url: String {
        switch self {
        case .minimal:
            return "https://estimatefee.com/n/6"
        case .normal:
            return "https://estimatefee.com/n/3"
        case .priority:
            return "https://estimatefee.com/n/2"
        }
    }
    
    public var testUrl: String {
        return url
    }
    
    public var method: String {
        return "GET"
    }
    
    public var body: Data? {
        return nil
    }
    
    public var headers: [String : String] {
        return [:]
    }
    
}
