//
//  SingleCommandtask.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public class SingleCommandTask<TCommand, TResult>: Task where TCommand: Command {
    public typealias TaskResult = TResult
    
    public var cardReader: CardReader
    public var delegate: CardManagerDelegate?
    
    private let command: TCommand
    
    public init(command: TCommand) {
        self.command = command
    }
    
    public func run(with environment: CardEnvironment, completion: @escaping (CompletionResult<TResult>, CardEnvironment?) -> Void) {
        executeCommand(command, reader: cardReader, environment: environment) { result, environment in
            switch result {
            case .success(let taskResult):
                completion(.success(taskResult), environment)
            case .failure(let error):
                completion(.failure(error), environment)
            }
        }
    }
}
