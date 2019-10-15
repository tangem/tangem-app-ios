//
//  CardManagerDelegate.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public protocol CardManagerDelegate: class {
    func showAlertMessage(_ text: String)
    func requestPin(completion: @escaping () -> CompletionResult<String, Error>)
}

final class DefaultCardManagerDelegate: CardManagerDelegate {
    private let reader: NFCReaderText
    
    init(reader: NFCReaderText) {
        self.reader = reader
    }
    
    func showAlertMessage(_ text: String) {
        reader.alertMessage = text
    }
    
    func requestPin(completion: @escaping () -> CompletionResult<String, Error>) {
    }
}
