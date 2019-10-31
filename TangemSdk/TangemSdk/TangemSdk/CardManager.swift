//
//  CardManager.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC

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
    private var cardEnvironmentRepository: [String:CardEnvironment] = [:]
    private var currentTask: AnyTask?
    
    public init(cardReader: CardReader, cardManagerDelegate: CardManagerDelegate) {
        self.cardReader = cardReader
        self.cardManagerDelegate = cardManagerDelegate
    }
    
    public func scanCard(callback: @escaping (TaskEvent<ScanEvent>) -> Void) {
        let task = ScanTask()
        runTask(task, callback: callback)
    }
    
    @available(iOS 13.0, *)
    public func sign(hashes: [Data], cardId: String, callback: @escaping (TaskEvent<SignResponse>) -> Void) {
        var signHashesCommand: SignHashesCommand
        do {
            signHashesCommand = try SignHashesCommand(hashes: hashes, cardId: cardId)
        } catch {
            if let taskError = error as? TaskError {
                callback(.completion(taskError))
            } else {
                callback(.completion(TaskError.genericError(error)))
            }
            return
        }
        
        let task = SingleCommandTask(signHashesCommand)
        runTask(task, cardId: cardId, callback: callback)
    }
    
    public func runTask<T>(_ task: Task<T>, cardId: String? = nil, callback: @escaping (TaskEvent<T>) -> Void) {
        guard CardManager.isNFCAvailable else {
            callback(.completion(TaskError.unsupported))
            return
        }
        
        guard !isBusy else {
            callback(.completion(TaskError.busy))
            return
        }
        currentTask = task
        let environment = fetchCardEnvironment(for: cardId)
        isBusy = true
        task.cardReader = cardReader
        task.delegate = cardManagerDelegate
        task.run(with: environment) {[weak self] taskResult in
            switch taskResult {
            case .event(let event):
                DispatchQueue.main.async {
                    callback(.event(event))
                }
            case .completion(let error):
                DispatchQueue.main.async {
                    callback(.completion(error))
                }
                self?.isBusy = false
                self?.currentTask = nil
            }
        }
    }
    
    @available(iOS 13.0, *)
    public func runCommand<T: CommandSerializer>(_ command: T, cardId: String? = nil, callback: @escaping (TaskEvent<T.CommandResponse>) -> Void) {
        let task = SingleCommandTask<T>(command)
        runTask(task, cardId: cardId, callback: callback)
    }
    
    private func fetchCardEnvironment(for cardId: String?) -> CardEnvironment {
        guard let cardId = cardId else {
            return CardEnvironment()
        }
        
        return cardEnvironmentRepository[cardId] ?? CardEnvironment()
    }
}

extension CardManager {
    public convenience init(cardReader: CardReader? = nil, cardManagerDelegate: CardManagerDelegate? = nil) {
        let reader = cardReader ?? CardReaderFactory().createDefaultReader()
        let delegate = cardManagerDelegate ?? DefaultCardManagerDelegate(reader: reader)
        self.init(cardReader: reader, cardManagerDelegate: delegate)
    }
}
