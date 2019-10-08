//
//  CardManager.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation


@available(iOS 13.0, *)
public class CardManager{
    public private(set) var card: Card? =  nil
    
    private let cardReader: CardReader
    private let cardManagerDelegate: CardManagerDelegate?
    private let cardEnvironmentRepository: CardEnvironmentRepository
    
    public init(cardReader: CardReader, dataStorage: DataStorage, cardManagerDelegate: CardManagerDelegate? = nil) {
        self.cardReader = cardReader
        self.cardManagerDelegate = cardManagerDelegate
        cardEnvironmentRepository = CardEnvironmentRepository(dataStorage: dataStorage)
    }
    
    public func scanCard(completion: @escaping (ScanResult) -> Void) {
        let task = ScanTask()
        runTask(task, completion: completion)
    }
    
    public func sign(completion: @escaping (SignResult) -> Void) {
        
        
        //[REDACTED_TODO_COMMENT]
    }
    
    func runTask<TaskResult>(_ task: Task<TaskResult>, completion: @escaping (TaskResult) -> Void) {
        task.cardReader = cardReader
        task.delegate = cardManagerDelegate
        task.cardEnvironmentRepository = cardEnvironmentRepository
        task.run(with: cardEnvironmentRepository.cardEnvironment, completion: completion)
    }
    
    func runCommand<AnyCommandSerializer>(_ commandSerializer: AnyCommandSerializer, completion: @escaping (CompletionResult<AnyCommandSerializer.CommandResponse>) -> Void)
        where AnyCommandSerializer: CommandSerializer {
            let task = SingleCommandTask<AnyCommandSerializer>(commandSerializer)
            task.cardReader = cardReader
            task.delegate = cardManagerDelegate
            task.cardEnvironmentRepository = cardEnvironmentRepository
            runTask(task, completion: completion)
    }
}
