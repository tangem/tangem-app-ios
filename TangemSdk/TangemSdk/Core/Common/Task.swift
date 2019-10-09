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
    case mappingError
    case errorProcessingCommand
    case invalidState
    case insNotSupported
    case generateChallengeFailed
}

@available(iOS 13.0, *)
open class Task<TaskResult> {
    var cardReader: CardReader!
    var delegate: CardManagerDelegate?
    var cardEnvironmentRepository: CardEnvironmentRepository!
    
    deinit {
        cardReader.stopSession()
    }
    
    public func run(with environment: CardEnvironment, completion: @escaping (TaskResult) -> Void) {
        guard cardReader != nil else {
            fatalError("Card reader is nil")
        }
        
        guard cardEnvironmentRepository != nil else {
            fatalError("CardEnvironmentRepository reader is nil")
        }
        
        cardReader.startSession()
    }
        
    func sendCommand<AnyCommandSerializer>(_ commandSerializer: AnyCommandSerializer, completion: @escaping (CompletionResult<AnyCommandSerializer.CommandResponse>) -> Void)
        where AnyCommandSerializer: CommandSerializer {
            
            let commandApdu = commandSerializer.serialize(with: cardEnvironmentRepository.cardEnvironment)
            cardReader.send(commandApdu: commandApdu) { [unowned self] commandResponse in
                switch commandResponse {
                case .success(let responseApdu):
                    guard let status = responseApdu.status else {
                        completion(.failure(TaskError.unknownStatus(sw: responseApdu.sw)))
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
                        //            if let newEnvironment = returnedEnvironment {
                        //                self?.cardEnvironmentRepository.cardEnvironment = newEnvironment
                        //            }

                        break
                    case .processCompleted, .pin1Changed, .pin2Changed, .pin3Changed, .pinsNotChanged:
                        if let responseData = commandSerializer.deserialize(with: self.cardEnvironmentRepository.cardEnvironment, from: responseApdu) {
                            completion(.success(responseData))
                        } else {
                            completion(.failure(TaskError.mappingError))
                        }
                    case .errorProcessingCommand:
                        completion(.failure(TaskError.errorProcessingCommand))
                    case .invalidState:
                        completion(.failure(TaskError.invalidState))
                    case .insNotSupported:
                        completion(.failure(TaskError.insNotSupported))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}
