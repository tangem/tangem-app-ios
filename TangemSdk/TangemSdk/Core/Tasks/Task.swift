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
    case invalidParams
    case needEncryption
    case vefificationFailed
    case cardError
    case tooMuchHashesInOneTransaction
    case emptyHashes
    case hashSizeMustBeEqual
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
    var cardReader: (CardReader & NFCReaderSessionAdapter)!
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
                    let tlv = responseApdu.getTlvData(encryptionKey: environment.encryptionKey)
                    if let ms = tlv?.value(for: .pause)?.toInt() {
                        self.delegate?.showSecurityDelay(remainingMilliseconds: ms)
                    }
                    
                    if tlv?.value(for: .flash) != nil {
                        self.cardReader.restartPolling()
                    } else {
                        self.sendCommand(commandSerializer, environment: environment, completion: completion)
                    }
                    
                case .needEcryption:
                    //[REDACTED_TODO_COMMENT]
                    DispatchQueue.main.async {
                        completion(.failure(TaskError.needEncryption), environment)
                    }
                case .invalidParams:
                    //[REDACTED_TODO_COMMENT]
                    DispatchQueue.main.async {
                        completion(.failure(TaskError.invalidParams), environment)
                    }
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
