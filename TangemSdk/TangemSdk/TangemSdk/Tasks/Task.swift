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

@available(iOS 13.0, *)
open class Task<TaskResult> {
    var cardReader: CardReader!
    weak var delegate: CardManagerDelegate?
    
    deinit {
        print("task deinit")
        delegate?.showAlertMessage(Localization.nfcAlertDefaultDone)
        cardReader.stopSession()
    }
    
    public final func run(with environment: CardEnvironment, completion: @escaping (TaskResult, CardEnvironment) -> Void) {
        guard cardReader != nil else {
            fatalError("Card reader is nil")
        }
        
        cardReader.startSession()
        onRun(environment: environment, completion: completion)
    }
    
    public func onRun(environment: CardEnvironment, completion: @escaping (TaskResult, CardEnvironment) -> Void) {
        
    }
    
    func sendCommand<T: CommandSerializer>(_ commandSerializer: T, environment: CardEnvironment, completion: @escaping (CommandEvent<T.CommandResponse>, CardEnvironment) -> Void) {
        
        var commandApdu: CommandApdu
        do {
            commandApdu = try commandSerializer.serialize(with: environment)
        } catch {
            DispatchQueue.main.async {
                completion(.failure(error), environment)
            }
            return
        }
        
        sendRequest(commandSerializer, apdu: commandApdu, environment: environment, completion: completion)
    }
    
    
    func sendRequest<T: CommandSerializer>(_ commandSerializer: T, apdu: CommandApdu, environment: CardEnvironment, completion: @escaping (CommandEvent<T.CommandResponse>, CardEnvironment) -> Void) {
        cardReader.send(commandApdu: apdu) { commandResponse in
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
                        print("Save flash")
                        self.cardReader.restartPolling()
                    }
                    self.sendRequest(commandSerializer, apdu: apdu, environment: environment, completion: completion)
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
                    do {
                        let responseData = try commandSerializer.deserialize(with: environment, from: responseApdu)
                        DispatchQueue.main.async {
                            completion(.success(responseData), environment)
                        }
                    } catch {
                        DispatchQueue.main.async {
                            completion(.failure(error), environment)
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
                        completion(.failure(TaskError.readerError(error)), environment)
                    }
                }
            }
        }
    }
}
