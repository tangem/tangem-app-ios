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
    private let
    
    public init(cardReader: CardReader, dataStorage: DataStorage, cardManagerDelegate: CardManagerDelegate? = nil) {
        self.cardReader = cardReader
        self.cardManagerDelegate = cardManagerDelegate
    
    }
    
    public func scanCard(completion: @escaping (ScanTaskResult) -> Void) {
        
    }
    
    func runTask<AnyTask>(_ task: AnyTask, environment: CardEnvironment? = nil,
                                      completion: @escaping (CompletionResult<AnyTask.TaskResult>) -> Void) where AnyTask: Task {

        
        task.run(with: environment ?? CardEnvironment()) { completionResult, returnedEnvironment in
            switch completionResult {
            case .success(let taskResult):
                completion(.success(taskResult))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
//        task.run(environment ?: cardEnvironmentRepository.cardEnvironment) {result, returnedEnvironment ->
//            //[REDACTED_TODO_COMMENT]
//            cardEnvironmentRepository.cardEnvironment = returnedEnvironment
//            callback.invoke(result)
//        }
    }

}

/*
open class CardManager(
        private val reader: CardReader,
        private val cardManagerDelegate: CardManagerDelegate? = null,
        dataStorage: DataStorage? = null) {

    private val cardEnvironmentRepository = CardEnvironmentRepository(dataStorage)

    var card: Card? = null
        private set

    fun scanCard(callback: (result: TaskResult) -> Unit) {

        val task = ScanTask(cardManagerDelegate, reader)

        runTask(task, cardEnvironmentRepository.cardEnvironment) {
            if (it is TaskResult.CommandCompleted && it.resultData is Card) {
                this.card = it.resultData
            }
            callback.invoke(it)
        }
    }

    fun signTransaction(signCommandData: SignCommandData,
                        callback: (result: TaskResult) -> Unit) {
        val task = SignTask(signCommandData, cardManagerDelegate, reader)
        runTask(task, cardEnvironmentRepository.cardEnvironment, callback)
    }

    fun runTask(task: Task, environment: CardEnvironment? = null,
                callback: (result: TaskResult) -> Unit) {

        task.run(environment ?: cardEnvironmentRepository.cardEnvironment) {result, returnedEnvironment ->
            //[REDACTED_TODO_COMMENT]
            cardEnvironmentRepository.cardEnvironment = returnedEnvironment
            callback.invoke(result)
        }
    }

    fun runCommand(command: Command,
                   environment: CardEnvironment? = null,
                   callback: (result: TaskResult) -> Unit) {
        val task = BasicTask(command, cardManagerDelegate, reader)
        runTask(task, environment, callback)
    }
}

sealed class TaskResult {
    data class Success(val resultData: Any) : TaskResult()
    data class CommandCompleted(val resultData: Any) : TaskResult()
    data class Error(val error: CardError) : TaskResult()
}
*/
