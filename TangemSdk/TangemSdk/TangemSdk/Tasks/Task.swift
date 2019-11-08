//
//  Task.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC

public protocol AnyTask {
    
}

public enum TaskEvent<TEvent> {
    case event(TEvent)
    case completion(TaskError? = nil)
}

public enum TaskError: Error, LocalizedError {
    //Serialize apdu errors
    case serializeCommandError
    
    //Card errors
    case unknownStatus(sw: UInt16)
    case errorProcessingCommand
    case invalidState
    case insNotSupported
    case invalidParams
    case needEncryption
    
    //Scan errors
    case vefificationFailed
    case cardError
    
    //Sign errors
    case tooMuchHashesInOneTransaction
    case emptyHashes
    case hashSizeMustBeEqual
    
    case busy
    case userCancelled
    case genericError(Error)
    case unsupported
    //NFC error
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

open class Task<TEvent>: AnyTask {
    var reader: CardReader!
    weak var delegate: CardManagerDelegate?
    
    deinit {
        print("task deinit")
    }
    
    public final func run(with environment: CardEnvironment, callback: @escaping (TaskEvent<TEvent>) -> Void) {
        guard reader != nil else {
            fatalError("Card reader is nil")
        }
        
        reader.startSession()
        onRun(environment: environment, callback: callback)
    }
    
    public func onRun(environment: CardEnvironment, callback: @escaping (TaskEvent<TEvent>) -> Void) {}
    
    public final func sendCommand<T: CommandSerializer>(_ commandSerializer: T, environment: CardEnvironment, callback: @escaping (Result<T.CommandResponse, TaskError>) -> Void) {
        let commandApdu = commandSerializer.serialize(with: environment)
        sendRequest(commandSerializer, apdu: commandApdu, environment: environment, callback: callback)
    }
    
    func sendRequest<T: CommandSerializer>(_ commandSerializer: T, apdu: CommandApdu, environment: CardEnvironment, callback: @escaping (Result<T.CommandResponse, TaskError>) -> Void) {
        reader.send(commandApdu: apdu) { [weak self] commandResponse in
            switch commandResponse {
            case .success(let responseApdu):
                guard let status = responseApdu.status else {
                    callback(.failure(TaskError.unknownStatus(sw: responseApdu.sw)))
                    return
                }
                
                switch status {
                case .needPause:
                    if let securityDelayResponse = commandSerializer.deserializeSecurityDelay(with: environment, from: responseApdu) {
                        self?.delegate?.showSecurityDelay(remainingMilliseconds: securityDelayResponse.remainingMilliseconds)
                        if securityDelayResponse.saveToFlash {
                             self?.reader.restartPolling()
                        }
                    }
                    self?.sendRequest(commandSerializer, apdu: apdu, environment: environment, callback: callback)
                case .needEcryption:
                    //[REDACTED_TODO_COMMENT]
                    
                    callback(.failure(TaskError.needEncryption))
                    
                case .invalidParams:
                    //[REDACTED_TODO_COMMENT]
                    
                    callback(.failure(TaskError.invalidParams))
                    
                case .processCompleted, .pin1Changed, .pin2Changed, .pin3Changed, .pinsNotChanged:
                    do {
                        let responseData = try commandSerializer.deserialize(with: environment, from: responseApdu)
                        callback(.success(responseData))
                    } catch {
                        if let taskError = error as? TaskError {
                            callback(.failure(taskError))
                        } else {
                            callback(.failure(TaskError.genericError(error)))
                        }
                    }
                case .errorProcessingCommand:
                    callback(.failure(TaskError.errorProcessingCommand))
                case .invalidState:
                    callback(.failure(TaskError.invalidState))
                    
                case .insNotSupported:
                    callback(.failure(TaskError.insNotSupported))
                }
            case .failure(let error):
                if error.code == .readerSessionInvalidationErrorUserCanceled {
                    callback(.failure(TaskError.userCancelled))
                } else {
                    callback(.failure(TaskError.readerError(error)))
                }
            }
        }
    }
}
