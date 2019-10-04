//
//  CardManagerDelegate.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public protocol CardManagerDelegate: class {
    func showSecurityDelay(remainingSeconds: Int)
    func requestPin(completion: @escaping () -> CompletionResult<String>)
}

class DefaultCardManagerDelegate: CardManagerDelegate {
    private let reader: NFCReaderText
    
    init(reader: NFCReaderText) {
        self.reader = reader
    }
    
    func showSecurityDelay(remainingSeconds: Int) {
        reader.alertMessage = "\(remainingSeconds)"
    }
    
    func requestPin(completion: @escaping () -> CompletionResult<String>) {
    }
}
