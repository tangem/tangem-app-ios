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
        //[REDACTED_TODO_COMMENT]
        let task = ScanTask()
        runTask(task) { completionResult in
            
        }
    }
    
    public func sign(completion: @escaping (SignResult) -> Void) {
        //[REDACTED_TODO_COMMENT]
    }
    
    func runTask<AnyTask>(_ task: AnyTask, environment: CardEnvironment? = nil,
                          completion: @escaping (CompletionResult<AnyTask.TaskResult>) -> Void) where AnyTask: Task {
        task.cardReader = cardReader
        task.delegate = cardManagerDelegate
        
        task.run(with: environment ?? cardEnvironmentRepository.cardEnvironment) {[weak self] completionResult, returnedEnvironment in
            switch completionResult {
            case .success(let taskResult):
                if let newEnvironment = returnedEnvironment {
                    self?.cardEnvironmentRepository.cardEnvironment = newEnvironment
                }
                completion(.success(taskResult))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func runCommand<AnyCommandSerializer>(_ commandSerializer: AnyCommandSerializer, environment: CardEnvironment? = nil, completion: @escaping (CompletionResult<AnyCommandSerializer.CommandResponse>) -> Void)
        where AnyCommandSerializer: CommandSerializer {
            let task = SingleCommandTask<AnyCommandSerializer,AnyCommandSerializer.CommandResponse>(commandSerializer)
            task.cardReader = cardReader
            task.delegate = cardManagerDelegate
            runTask(task, environment: environment,completion: completion)
    }
}
