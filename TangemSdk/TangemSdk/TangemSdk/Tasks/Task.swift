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
    case success(CardEnvironment)
    case failure(TaskError)
}

public enum TaskError: Error, LocalizedError {
    //Serialize apdu errors
    case serializeCommandError
    case cardIdMissing
    
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
        cardReader.stopSession()
    }
    
    public final func run(with environment: CardEnvironment, completion: @escaping (TaskEvent<TEvent>) -> Void) {
        guard cardReader != nil else {
            fatalError("Card reader is nil")
        }
        
        cardReader.startSession()
        onRun(environment: environment, completion: completion)
    }
    
    public func onRun(environment: CardEnvironment, completion: @escaping (TaskEvent<TEvent>) -> Void) {}
    
    func sendCommand<T: CommandSerializer>(_ commandSerializer: T, environment: CardEnvironment, completion: @escaping (TaskEvent<T.CommandResponse>) -> Void) {
        var commandApdu: CommandApdu
        do {
            commandApdu = try commandSerializer.serialize(with: environment)
        } catch {
            if let taskError = error as? TaskError {
                completion(.failure(taskError))
            } else {
                completion(.failure(TaskError.genericError(error)))
            }
            return
        }
        sendRequest(commandSerializer, apdu: commandApdu, environment: environment, completion: completion)
    }
    
    func sendRequest<T: CommandSerializer>(_ commandSerializer: T, apdu: CommandApdu, environment: CardEnvironment, completion: @escaping (TaskEvent<T.CommandResponse>) -> Void) {
        cardReader.send(commandApdu: apdu) { commandResponse in
            switch commandResponse {
            case .success(let responseApdu):
                guard let status = responseApdu.status else {
                    completion(.failure(TaskError.unknownStatus(sw: responseApdu.sw)))
                    return
                }
                
                switch status {
                case .needPause:
                    let tlv = responseApdu.getTlvData(encryptionKey: environment.encryptionKey)
                    if let ms = tlv?.value(for: .pause)?.toInt() {
                        self.delegate?.showSecurityDelay(remainingMilliseconds: ms)
                    }
                    if tlv?.value(for: .flash) != nil {
                        print("Save flash")
                        self.cardReader.restartPolling()
                    }
                    self.sendRequest(commandSerializer, apdu: apdu, environment: environment, completion: completion)
                case .needEcryption:
                    //[REDACTED_TODO_COMMENT]
                    
                    completion(.failure(TaskError.needEncryption))
                    
                case .invalidParams:
                    //[REDACTED_TODO_COMMENT]
                    
                    completion(.failure(TaskError.invalidParams))
                    
                case .processCompleted, .pin1Changed, .pin2Changed, .pin3Changed, .pinsNotChanged:
                    do {
                        let responseData = try commandSerializer.deserialize(with: environment, from: responseApdu)
                        completion(.event(responseData))
                        completion(.success(environment))
                    } catch {
                        if let taskError = error as? TaskError {
                            completion(.failure(taskError))
                        } else {
                            completion(.failure(TaskError.genericError(error)))
                        }
                    }
                case .errorProcessingCommand:
                    completion(.failure(TaskError.errorProcessingCommand))
                case .invalidState:
                    completion(.failure(TaskError.invalidState))
                    
                case .insNotSupported:
                    completion(.failure(TaskError.insNotSupported))
                }
            case .failure(let error):
                if error.code == .readerSessionInvalidationErrorUserCanceled {
                    completion(.failure(TaskError.userCancelled))
                } else {
                    completion(.failure(TaskError.readerError(error)))
                }
            }
        }
    }
}
