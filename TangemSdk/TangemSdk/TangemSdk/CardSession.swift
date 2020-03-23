//
//  CardSession.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public typealias CommandResult<T> = (Result<T, TaskError>) -> Void

public struct CardSessionConfig {
    public var environment: CardEnvironment = CardEnvironment()
    public var runPreflightRead: Bool = true
    public var initialMessage: String? = nil
}


public class CardSession {
    public var config: CardSessionConfig
    
    private let reader: CardReader
    private let viewDelegate: CardManagerDelegate
    private var currentCommand: AnyCommand?
    private var isBusy: Bool = false
    private var needStopSession = false
    
    public init(reader: CardReader, viewDelegate: CardManagerDelegate, config: CardSessionConfig? = nil) {
        self.reader = reader
        self.viewDelegate = viewDelegate
        self.config = config ?? CardSessionConfig()
    }
    
    
    public func stopSession(message: String? = nil) {
        if let message = message {
            viewDelegate.showAlertMessage(message)
        }
        reader.stopSession()
    }
    
    public func stopSession(error: Error) {
        reader.stopSession(with: error.localizedDescription)
    }
    
    public func run<T: CommandSerializer>(_ command: T, stopSession: Bool, completion: @escaping CommandResult<T.CommandResponse>) {
        guard CardManager.isNFCAvailable else {
            completion(.failure(TaskError.unsupportedDevice))
            return
        }
        
        guard !isBusy else {
            completion(.failure(TaskError.busy))
            return
        }
        
        needStopSession = stopSession
        currentCommand = command
        isBusy = true
        
        //[REDACTED_TODO_COMMENT]
        reader.startSession(with: config.initialMessage)
        
        if #available(iOS 13.0, *), config.runPreflightRead {
            preflightRead(environment: config.environment) {[unowned self] result in
                switch result {
                case .success(let card):
                    self.runCommand(command, currentCard: card, completion: completion)
                case .failure(let error):
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    self.completeCommand(stopSession: true)
                }
            }
        } else {
            runCommand(command, completion: completion)
        }
    }
    
    private func runCommand<T: CommandSerializer>(_ command: T, currentCard: Card? = nil, completion: @escaping CommandResult<T.CommandResponse>) {
        command.run(session: self, environment: config.environment, currentCard: currentCard) {[unowned self] commandResult in
            switch commandResult {
            case .success(let commandResponse):
                DispatchQueue.main.async {
                    completion(.success(commandResponse))
                }
                 self.completeCommand(stopSession: needStopSession)
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                 self.completeCommand(stopSession: true)
            }
        }
    }
    
    private func completeCommand(stopSession: Bool) {
        self.isBusy = false
        self.currentCommand = nil
        if needStopSession {
            self.stopSession()
        }
    }
    
    
    
    @available(iOS 13.0, *)
    private func preflightRead(environment: CardEnvironment, completion: @escaping (Result<ReadCommand.CommandResponse, TaskError>) -> Void) {
        sendCommand(ReadCommand(), environment: environment) { [weak self] readResult in
            guard let self = self else { return }
            
            switch readResult {
            case .failure(let error):
                self.stopSession(error: error)
                completion(.failure(error))
            case .success(let readResponse):
                if let expectedCardId = environment.cardId,
                    let actualCardId = readResponse.cardId,
                    expectedCardId != actualCardId {
                    let error = TaskError.wrongCard
                    self.stopSession(error: error)
                    completion(.failure(error))
                    return
                }
                
                var newEnvironment = environment
                if newEnvironment.cardId == nil {
                    newEnvironment.cardId = readResponse.cardId
                }
                completion(.success(readResponse))
            }
        }
    }
}

extension CardSession: CommandTransiever {
    /**
     * This method should be called by Tasks in their `sessionDidStart` method wherever
     * they need to communicate with the Tangem Card by launching commands.
     */
    public final func sendCommand<T: CommandSerializer>(_ command: T, environment: CardEnvironment, callback: @escaping CommandResult<T.CommandResponse>) {
        //[REDACTED_TODO_COMMENT]
        if let commandApdu = try? command.serialize(with: environment) {
            sendRequest(command, apdu: commandApdu, environment: environment, callback: callback)
        } else {
            callback(.failure(TaskError.serializeCommandError))
        }
    }
    
    private func sendRequest<T: CommandSerializer>(_ command: T, apdu: CommandApdu, environment: CardEnvironment, callback: @escaping CommandResult<T.CommandResponse>) {
        reader.send(commandApdu: apdu) { [weak self] commandResponse in
            switch commandResponse {
            case .success(let responseApdu):
                switch responseApdu.statusWord {
                case .needPause:
                    if let securityDelayResponse = command.deserializeSecurityDelay(with: environment, from: responseApdu) {
                        self?.viewDelegate.showSecurityDelay(remainingMilliseconds: securityDelayResponse.remainingMilliseconds)
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
}

public protocol CommandTransiever {
    func sendCommand<T: CommandSerializer>(_ command: T, environment: CardEnvironment, callback: @escaping CommandResult<T.CommandResponse>)
}
