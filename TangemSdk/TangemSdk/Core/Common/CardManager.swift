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
    
    public func scanCard(completion: @escaping (ScanTaskResult) -> Void) {
        let task = ScanTask()
        runTask(task) { completionResult in
            
        }
    }
    
    public func sign(completion: @escaping (SignTaskResult) -> Void) {
        //[REDACTED_TODO_COMMENT]
    }
    
    func runTask<AnyTask>(_ task: AnyTask, environment: CardEnvironment? = nil,
                          completion: @escaping (CompletionResult<AnyTask.TaskResult>) -> Void) where AnyTask: Task {
        task.cardReader = cardReader
        task.delegate = cardManagerDelegate
        
        task.run(with: environment ?? cardEnvironmentRepository.cardEnvironment) { completionResult, returnedEnvironment in
            switch completionResult {
            case .success(let taskResult):
                completion(.success(taskResult))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func runCommand<AnyCommand>(_ command: AnyCommand, environment: CardEnvironment? = nil, completion: (CompletionResult<AnyCommand.CommandResponse>) -> Void)
        where AnyCommand: Command {
            let task = SingleCommandTask<AnyCommand,AnyCommand.CommandResponse>(command: command)
            task.cardReader = cardReader
            task.delegate = cardManagerDelegate
            
            runTask(task, environment: environment) { result in
                switch result {
                case.success(let commandResponse):
                    completion(.success(commandResponse))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    
}
