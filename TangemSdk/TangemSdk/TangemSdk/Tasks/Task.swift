//
//  Task.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC

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

open class Task<TEvent> {
    var cardReader: CardReader!
    weak var delegate: CardManagerDelegate?
    
    deinit {
        print("task deinit")
        delegate?.showAlertMessage(Localization.nfcAlertDefaultDone)
        cardReader?.stopSession()
    }
    
    public final func run(with environment: CardEnvironment, callback: @escaping (TaskEvent<TEvent>) -> Void) {
        guard cardReader != nil else {
            fatalError("Card reader is nil")
        }
        
        cardReader.startSession()
        onRun(environment: environment, callback: callback)
    }
    
    public func onRun(environment: CardEnvironment, callback: @escaping (TaskEvent<TEvent>) -> Void) {}
    
    public final func sendCommand<T: CommandSerializer>(_ commandSerializer: T, environment: CardEnvironment, callback: @escaping (TaskEvent<T.CommandResponse>) -> Void) {
        let commandApdu = commandSerializer.serialize(with: environment)
        sendRequest(commandSerializer, apdu: commandApdu, environment: environment, callback: callback)
    }
    
    func sendRequest<T: CommandSerializer>(_ commandSerializer: T, apdu: CommandApdu, environment: CardEnvironment, callback: @escaping (TaskEvent<T.CommandResponse>) -> Void) {
        cardReader.send(commandApdu: apdu) { commandResponse in
            switch commandResponse {
            case .success(let responseApdu):
                guard let status = responseApdu.status else {
                    callback(.completion(TaskError.unknownStatus(sw: responseApdu.sw)))
                    return
                }
                
                switch status {
                case .needPause:
                    if let securityDelayResponse = commandSerializer.deserializeSecurityDelay(with: environment, from: responseApdu) {
                        self.delegate?.showSecurityDelay(remainingMilliseconds: securityDelayResponse.remainingMilliseconds)
                        if securityDelayResponse.saveToFlash {
                             self.cardReader.restartPolling()
                        }
                    }
                    self.sendRequest(commandSerializer, apdu: apdu, environment: environment, callback: callback)
                case .needEcryption:
                    //[REDACTED_TODO_COMMENT]
                    
                    callback(.completion(TaskError.needEncryption))
                    
                case .invalidParams:
                    //[REDACTED_TODO_COMMENT]
                    
                    callback(.completion(TaskError.invalidParams))
                    
                case .processCompleted, .pin1Changed, .pin2Changed, .pin3Changed, .pinsNotChanged:
                    do {
                        let responseData = try commandSerializer.deserialize(with: environment, from: responseApdu)
                        callback(.event(responseData))
                        callback(.completion())
                    } catch {
                        if let taskError = error as? TaskError {
                            callback(.completion(taskError))
                        } else {
                            callback(.completion(TaskError.genericError(error)))
                        }
                    }
                case .errorProcessingCommand:
                    callback(.completion(TaskError.errorProcessingCommand))
                case .invalidState:
                    callback(.completion(TaskError.invalidState))
                    
                case .insNotSupported:
                    callback(.completion(TaskError.insNotSupported))
                }
            case .failure(let error):
                if error.code == .readerSessionInvalidationErrorUserCanceled {
                    callback(.completion(TaskError.userCancelled))
                } else {
                    callback(.completion(TaskError.readerError(error)))
                }
            }
        }
    }
}
