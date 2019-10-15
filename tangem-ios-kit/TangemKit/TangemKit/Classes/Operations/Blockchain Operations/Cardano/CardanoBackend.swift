//
//  CardanoApi.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import GBAsyncOperation

enum CardanoBackend: String{
    case adaliteURL1 = "https://explorer2.adalite.io"
    case adaliteURL2 = "https://nodes.southeastasia.cloudapp.azure.com"
    
    static var current: CardanoBackend = adaliteURL1
    static func switchBackend() {
        current = .adaliteURL2
    }
}


protocol CardanoBackendHandler: GBAsyncOperation {
    var retryCount: Int {get set}
    func handleError(_ error: Error)
    func failOperationWith(error: Error)
}

extension CardanoBackendHandler {
    func handleError(_ error: Error) {
        retryCount -= 1
        guard retryCount >= 0 else {
            self.failOperationWith(error: error)
            return
        }
        
        CardanoBackend.switchBackend()
        main()
    }
}
