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
    
    public func scanCard(with environment: CardEnvironment? = nil, callback: @escaping (ScanEvent, CardEnvironment) -> Void) {
        let task = ScanTask()
        runTask(task, environment: environment, callback: callback)
    }
    
    public func sign(hashes: [Data], environment: CardEnvironment, callback: @escaping (CommandEvent<SignResponse>, CardEnvironment) -> Void) {
        var signHashesCommand: SignHashesCommand
        do {
            signHashesCommand = try SignHashesCommand(hashes: hashes)
        } catch {
            callback(.failure(error), environment)
            return
        }
        
        let task = SingleCommandTask(signHashesCommand)
        runTask(task, environment: environment, callback: callback)        
    }
    
    func runTask<TaskEvent>(_ task: Task<TaskEvent>, environment: CardEnvironment? = nil, callback: @escaping (TaskEvent, CardEnvironment) -> Void) {
        task.cardReader = cardReader
        task.delegate = cardManagerDelegate
        task.run(with: environment ?? CardEnvironment(), completion: callback)
    }
    
    func runCommand<T: CommandSerializer>(_ commandSerializer: T, environment: CardEnvironment? = nil, completion: @escaping (CommandEvent<T.CommandResponse>, CardEnvironment) -> Void) {
        let task = SingleCommandTask<T>(commandSerializer)
        runTask(task, environment: environment, callback: completion)
    }
}

@available(iOS 13.0, *)
extension CardManager {
    public convenience init(cardReader: CardReader & NFCReaderText = NFCReader(), cardManagerDelegate: CardManagerDelegate? = nil) {
        let delegate = cardManagerDelegate ?? DefaultCardManagerDelegate(reader: cardReader)
        self.init(cardReader: cardReader, cardManagerDelegate: delegate)
    }
}
