//
//  ScanTask.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public enum ScanResult {
    case onRead
    case onVerify
    case failure(Error)
}


@available(iOS 13.0, *)
public class ScanTask: Task {
    public typealias TaskResult = ScanResult
    
    public var cardReader: CardReader?
    public var delegate: CardManagerDelegate?
    
    public func run(with environment: CardEnvironment, completion: @escaping (CompletionResult<ScanResult>, CardEnvironment?) -> Void) {
        //[REDACTED_TODO_COMMENT]
    }
}
