//
//  Task.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public enum TaskError: Error {
    case unknownStatus(sw: UInt16)
    case cardReaderNotSet
    case mappingError
    case errorProcessingCommand
    case invalidState
    case insNotSupported
}

@available(iOS 13.0, *)
public protocol Task: class {
    associatedtype TaskResult
    
    var cardReader: CardReader? {get set}
    var delegate: CardManagerDelegate? {get set}
    
    func run(with environment: CardEnvironment, completion: @escaping (CompletionResult<TaskResult>, CardEnvironment?) -> Void )
}

@available(iOS 13.0, *)
extension Task {
    func sendCommand<AnyCommandSerializer>(_ commandSerializer: AnyCommandSerializer, environment: CardEnvironment, completion: @escaping (CompletionResult<AnyCommandSerializer.CommandResponse>, CardEnvironment?) -> Void)
        where AnyCommandSerializer: CommandSerializer {
            guard let reader = cardReader else {
                completion(.failure(TaskError.cardReaderNotSet), nil)
                return
            }
            
            let commandApdu = commandSerializer.serialize(with: environment)
            reader.send(commandApdu: commandApdu) { commandResponse in
                switch commandResponse {
                case .success(let responseApdu):
                    guard let status = responseApdu.status else {
                        completion(.failure(TaskError.unknownStatus(sw: responseApdu.sw)), nil)
                        return
                    }
                    
                    switch status {
                    case .needPause:
                        //[REDACTED_TODO_COMMENT]
                        break
                    case .needEcryption:
                        //[REDACTED_TODO_COMMENT]
                        break
                    case .invalidParams:
                        //[REDACTED_TODO_COMMENT]
                        break
                    case .processCompleted, .pin1Changed, .pin2Changed, .pin3Changed, .pinsNotChanged:
                        if let responseData = commandSerializer.deserialize(with: environment, from: responseApdu) {
                            completion(.success(responseData), nil)
                        } else {
                            completion(.failure(TaskError.mappingError), nil)
                        }
                    case .errorProcessingCommand:
                        completion(.failure(TaskError.errorProcessingCommand), nil)
                    case .invalidState:
                        completion(.failure(TaskError.invalidState), nil)
                    case .insNotSupported:
                        completion(.failure(TaskError.insNotSupported), nil)
                    }
                case .failure(let error):
                    completion(.failure(error), nil)
                }
            }
    }
}
