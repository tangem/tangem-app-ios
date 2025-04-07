//
//  TangemURLSessionBuilder.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum TangemURLSessionBuilder {
    public static func makeSession(configuration: URLSessionConfiguration = .defaultConfiguration) -> URLSession {
        let session = URLSession(configuration: configuration, delegate: ForcedCTURLSessionDelegate(), delegateQueue: nil)
        return session
    }
}
