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


public final class CardManager {
    public static var isNFCAvailable: Bool {
        #if canImport(CoreNFC)
        if NSClassFromString("NFCNDEFReaderSession") == nil { return false }
        
        return NFCNDEFReaderSession.readingAvailable
        #else
        return false
        #endif
    }
    
    public var isBusy: Bool = false
    
    private let cardReader: CardReader
    private let cardManagerDelegate: CardManagerDelegate
    
    public init(cardReader: CardReader, cardManagerDelegate: CardManagerDelegate) {
        self.cardReader = cardReader
        self.cardManagerDelegate = cardManagerDelegate
    }
    
    public func scanCard(with environment: CardEnvironment? = nil, callback: @escaping (TaskEvent<ScanEvent>) -> Void) {
        if #available(iOS 13.0, *) {
            let task = ScanTask()
            runTask(task, environment: environment, callback: callback)
        } else {
            // Fallback on earlier versions
        }
        
    }
    
    @available(iOS 13.0, *)
    public func sign(hashes: [Data], environment: CardEnvironment, callback: @escaping (TaskEvent<SignResponse>) -> Void) {
        var signHashesCommand: SignHashesCommand
        do {
            signHashesCommand = try SignHashesCommand(hashes: hashes)
        } catch {
            if let taskError = error as? TaskError {
                callback(.failure(taskError))
            } else {
                callback(.failure(TaskError.genericError(error)))
            }
            return
        }
        
        let task = SingleCommandTask(signHashesCommand)
        runTask(task, environment: environment, callback: callback)        
    }
    
    @available(iOS 13.0, *)
    func runTask<T>(_ task: Task<T>, environment: CardEnvironment? = nil, callback: @escaping (TaskEvent<T>) -> Void) {
        guard !isBusy else {
            callback(.failure(TaskError.busy))
            return
        }
        
        isBusy = true
        task.cardReader = cardReader
        task.delegate = cardManagerDelegate
        task.run(with: environment ?? CardEnvironment()) { taskResult in
            DispatchQueue.main.async {
                switch taskResult {
                case .event(let event):
                    callback(.event(event))
                case .success(let environment):
                    callback(.success(environment))
                    self.isBusy = false
                case .failure(let error):
                    callback(.failure(error))
                    self.isBusy = false
                }
            }
        }
    }
    
    @available(iOS 13.0, *)
    func runCommand<T: CommandSerializer>(_ commandSerializer: T, environment: CardEnvironment? = nil, completion: @escaping (TaskEvent<T.CommandResponse>) -> Void) {
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
