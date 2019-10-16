//
//  CardManager.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
#if canImport(CoreNFC)
import CoreNFC
#endif

@available(iOS 13.0, *)
public final class CardManager {
    public static var isNFCAvailable: Bool {
        #if canImport(CoreNFC)
        if NSClassFromString("NFCNDEFReaderSession") == nil { return false }
        
        return NFCNDEFReaderSession.readingAvailable
        #else
        return false
        #endif
    }
    
    private let cardReader: CardReader
    private let cardManagerDelegate: CardManagerDelegate
    
    public init(cardReader: CardReader, cardManagerDelegate: CardManagerDelegate) {
        self.cardReader = cardReader
        self.cardManagerDelegate = cardManagerDelegate
    }
    
    public func scanCard(with environment: CardEnvironment? = nil, completion: @escaping (ScanResult, CardEnvironment) -> Void) {
        let task = ScanTask()
        runTask(task, environment: environment, completion: completion)
    }
    
    public func sign(with environment: CardEnvironment?, completion: @escaping (SignResult) -> Void) {
        //[REDACTED_TODO_COMMENT]
    }
    
    func runTask<TaskResult>(_ task: Task<TaskResult>, environment: CardEnvironment?, completion: @escaping (TaskResult, CardEnvironment) -> Void) {
        task.cardReader = cardReader
        task.delegate = cardManagerDelegate
        task.run(with: environment ?? CardEnvironment(), completion: completion)
    }
    
    func runCommand<T: CommandSerializer>(_ commandSerializer: T, environment: CardEnvironment?, completion: @escaping (CancellableCompletionResult<T.CommandResponse, TaskError>, CardEnvironment) -> Void) {
        let task = SingleCommandTask<T>(commandSerializer)
        runTask(task, environment: environment, completion: completion)
    }
}

@available(iOS 13.0, *)
extension CardManager {
    public convenience init(cardReader: CardReader = NFCReader(), cardManagerDelegate: CardManagerDelegate? = nil) {
        let delegate = cardManagerDelegate ?? DefaultCardManagerDelegate(reader: cardReader as! NFCReaderText)
        self.init(cardReader: cardReader, cardManagerDelegate: delegate)
    }
}
