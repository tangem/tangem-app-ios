//
//  Task.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC

protocol AnyTask {
    
}

/**
 * Events that are are sent in callbacks from `Task`.
 * `event(TEvent)`:  A callback that is triggered by a `Task`.
 * `completion(TaskError? = nil)` A callback that is triggered when a `Task` is completed. `TaskError` is nil if it's a successful completion of a `Task`
 */
public enum TaskEvent<TEvent> {
    case event(TEvent)
    case completion(TaskError? = nil)
}

/**
 * An error class that represent typical errors that may occur when performing Tangem SDK tasks.
 * Errors are propagated back to the caller in callbacks.
 */
public enum TaskError: Int, Error, LocalizedError {
    //Serialize apdu errors
    case serializeCommandError = 1001
    case encodingError = 1002
    case missingTag = 1003
    case wrongType = 1004
    case convertError = 1005
    
    //Card errors
    case unknownStatus = 2001
    case errorProcessingCommand = 2002
    case missingPreflightRead = 2003
    case invalidState = 2004
    case insNotSupported = 2005
    case invalidParams = 2006
    case needEncryption = 2007
    
    //Scan errors
    case verificationFailed = 3000
    case cardError = 3001
    case wrongCard = 3002
    case tooMuchHashesInOneTransaction = 3003
    case emptyHashes = 3004
    case hashSizeMustBeEqual = 3005
    
    case busy = 4000
    case userCancelled = 4001
    case unsupportedDevice = 4002
    //NFC error
    case nfcStuck = 5000
    case nfcTimeout = 5001
    case nfcReaderError = 5002
    
    case unknownError = 6000
    
    case missingCounter = 7001
    
    public var errorDescription: String? {
        switch self {
        case .nfcTimeout:
            return Localization.nfcSessionTimeout
        case .nfcStuck:
            return Localization.nfcStuckError
        default:
            return Localization.genericErrorCode("\(self.rawValue)")
        }
    }
    
    public var isUserCancelled: Bool {
        if case .userCancelled = self {
            return true
        } else {
            return false
        }
    }
    
    public static func parse(_ error: Error) -> TaskError {
        if let readerError = error as? NFCReaderError {
            switch readerError.code {
            case .readerSessionInvalidationErrorUserCanceled:
                return .userCancelled
            case .readerSessionInvalidationErrorSystemIsBusy:
                return .nfcStuck
            default:
                return .nfcReaderError
            }
        } else {
            return (error as? TaskError) ?? TaskError.unknownError
        }
    }
}

/**
 * Allows to perform a group of commands interacting between the card and the application.
 * A task opens an NFC session, sends commands to the card and receives its responses,
 * repeats the commands if needed, and closes session after receiving the last answer.
 */
open class Task<TEvent>: AnyTask {
    var reader: CardReader!
    
    ///  If `true`, the task will execute `Read Command`  before main logic and will return `currentCard` in `onRun` or throw an error if some check will not pass. Eg. the wrong card was scanned
    var performPreflightRead: Bool = true
    
    weak var delegate: CardManagerDelegate?
    
    deinit {
        print("task deinit")
    }
    
    /**
     * This method should be called to run the `Task` and perform all its operations.
     *
     * - Parameter environment: Relevant current version of a card environment
     * - Parameter callback: It will be triggered during the performance of the `Task`
     */
    public final func run(with environment: CardEnvironment, callback: @escaping (TaskEvent<TEvent>) -> Void) {
        guard reader != nil else {
            fatalError("Card reader is nil")
        }
        
        if delegate != nil {
            reader.tagDidConnect = { [weak self] in
                self?.delegate?.tagDidConnect()
            }
        }
        reader.startSession()
        if #available(iOS 13.0, *), performPreflightRead {
            preflightRead(environment: environment, callback: callback)
        } else {
            onRun(environment: environment, currentCard: nil, callback: callback)
        }
    }
    
    /**
     * In this method the individual Tasks' logic should be implemented.
     * - Parameter currentCard: This is the result of preflight `Read Command`. It will be  nil if `performPreflightRead` was set to `false`
     */
    public func onRun(environment: CardEnvironment, currentCard: Card?, callback: @escaping (TaskEvent<TEvent>) -> Void) {}
    
    /**
     * This method should be called by Tasks in their `onRun` method wherever
     * they need to communicate with the Tangem Card by launching commands.
     */
    public final func sendCommand<T: CommandSerializer>(_ command: T, environment: CardEnvironment, callback: @escaping (Result<T.CommandResponse, TaskError>) -> Void) {
        //[REDACTED_TODO_COMMENT]
        if let commandApdu = try? command.serialize(with: environment) {
            sendRequest(command, apdu: commandApdu, environment: environment, callback: callback)
        } else {
            callback(.failure(TaskError.serializeCommandError))
        }
    }
    
    private func sendRequest<T: CommandSerializer>(_ command: T, apdu: CommandApdu, environment: CardEnvironment, callback: @escaping (Result<T.CommandResponse, TaskError>) -> Void) {
        reader.send(commandApdu: apdu) { [weak self] commandResponse in
            switch commandResponse {
            case .success(let responseApdu):
                switch responseApdu.statusWord {
                case .needPause:
                    if let securityDelayResponse = command.deserializeSecurityDelay(with: environment, from: responseApdu) {
                        self?.delegate?.showSecurityDelay(remainingMilliseconds: securityDelayResponse.remainingMilliseconds)
                        if securityDelayResponse.saveToFlash {
                            self?.reader.restartPolling()
                        }
                    }
                    self?.sendRequest(command, apdu: apdu, environment: environment, callback: callback)
                case .needEcryption:
                    //[REDACTED_TODO_COMMENT]
                    
                    callback(.failure(TaskError.needEncryption))
                    
                case .invalidParams:
                    //[REDACTED_TODO_COMMENT]
                    
                    callback(.failure(TaskError.invalidParams))
                    
                case .processCompleted, .pin1Changed, .pin2Changed, .pin3Changed:
                    do {
                        let responseData = try command.deserialize(with: environment, from: responseApdu)
                        callback(.success(responseData))
                    } catch {
                        print(error.localizedDescription)
                        callback(.failure(TaskError.parse(error)))
                    }
                case .errorProcessingCommand:
                    callback(.failure(TaskError.errorProcessingCommand))
                case .invalidState:
                    callback(.failure(TaskError.invalidState))
                    
                case .insNotSupported:
                    callback(.failure(TaskError.insNotSupported))
                case .unknown:
                    print("Unknown sw: \(responseApdu.sw)")
                    callback(.failure(TaskError.unknownStatus))
                }
            case .failure(let error):
                callback(.failure(error))
            }
        }
    }
    
    @available(iOS 13.0, *)
    private func preflightRead(environment: CardEnvironment, callback: @escaping (TaskEvent<TEvent>) -> Void) {
        sendCommand(ReadCommand(), environment: environment) { [unowned self] readResult in
            switch readResult {
            case .failure(let error):
                self.reader.stopSession(errorMessage: error.localizedDescription)
                callback(.completion(error))
            case .success(let readResponse):
                if let expectedCardId = environment.cardId,
                    let actualCardId = readResponse.cardId,
                    expectedCardId != actualCardId {
                    let error = TaskError.wrongCard
                    self.reader.stopSession(errorMessage: error.localizedDescription)
                    callback(.completion(error))
                    return
                }
                
                var newEnvironment = environment
                if newEnvironment.cardId == nil {
                    newEnvironment.cardId = readResponse.cardId
                }
                self.onRun(environment: newEnvironment, currentCard: readResponse, callback: callback)
            }
        }
    }
}
