//
//  ScanTask.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public enum ScanTaskResult {
    case onRead
    case onVerify
    case failure(Error)
}


@available(iOS 13.0, *)
public class ScanTask: Task {
    public typealias TaskResult = ScanTaskResult
    
    public var cardReader: CardReader?
    public var delegate: CardManagerDelegate?
    
    public func run(with environment: CardEnvironment, completion: @escaping (CompletionResult<ScanTaskResult>, CardEnvironment?) -> Void) {
        
    }
}
