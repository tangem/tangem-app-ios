//
//  Task.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC

public enum TaskError: Error, LocalizedError {
    case unknownStatus(sw: UInt16)
    case mappingError
    case errorProcessingCommand
    case invalidState
    case insNotSupported
    case vefificationFailed
    case cardError
    case nfcUnavailable
    case readerError(NFCReaderError)
    
    public var localizedDescription: String {
        switch self {
        case .readerError(let nfcError):
            return nfcError.localizedDescription
        default:
            return "\(self)"
        }
    }
}

@available(iOS 13.0, *)
open class Task<TaskResult> {
    var cardReader: CardReader!
    var delegate: CardManagerDelegate?
    
    public final func run(with environment: CardEnvironment, completion: @escaping (TaskResult, CardEnvironment) -> Void) {
        guard cardReader != nil else {
            fatalError("Card reader is nil")
        }
        
        cardReader.startSession()
        onRun(environment: environment, completion: completion)
    }
    
    public func onRun(environment: CardEnvironment, completion: @escaping (TaskResult, CardEnvironment) -> Void) {
        
    }
    
    func sendCommand<T: CommandSerializer>(_ commandSerializer: T, environment: CardEnvironment, completion: @escaping (CancellableCompletionResult<T.CommandResponse, TaskError>, CardEnvironment) -> Void) {
        let commandApdu = commandSerializer.serialize(with: environment)
        cardReader.send(commandApdu: commandApdu) { [weak self] commandResponse in
            guard let self = self else { return }
            
            switch commandResponse {
            case .success(let responseApdu):
                guard let status = responseApdu.status else {
                    DispatchQueue.main.async {
                        completion(.failure(TaskError.unknownStatus(sw: responseApdu.sw)), environment)
                    }
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
                    if let responseData = commandSerializer.deserialize(with: environment, from: responseApdu) {
                        DispatchQueue.main.async {
                            completion(.success(responseData), environment)
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(.failure(TaskError.mappingError), environment)
                        }
                    }
                case .errorProcessingCommand:
                    DispatchQueue.main.async {
                        completion(.failure(TaskError.errorProcessingCommand), environment)
                    }
                case .invalidState:
                    DispatchQueue.main.async {
                        completion(.failure(TaskError.invalidState), environment)
                    }
                case .insNotSupported:
                    DispatchQueue.main.async {
                        completion(.failure(TaskError.insNotSupported), environment)
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    if error.code == .readerSessionInvalidationErrorUserCanceled {
                        completion(.userCancelled, environment)
                    } else {
                        completion(.failure(.readerError(error)), environment)
                    }
                }
            }
        }
    }
}
