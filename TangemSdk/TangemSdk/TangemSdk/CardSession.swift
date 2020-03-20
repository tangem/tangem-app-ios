//
//  CardSession.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public class CardSession {
    private let reader: CardReader
    private let viewDelegate: CardManagerDelegate
    private let cardSessionDelegate: CardSessionDelegate
    
    public init(reader: CardReader, viewDelegate: CardManagerDelegate, cardSessionDelegate: CardSessionDelegate) {
        self.reader = reader
        self.viewDelegate = viewDelegate
        self.cardSessionDelegate = cardSessionDelegate
    }
    
    public func startSession(environment: CardEnvironment,
                             runPreflightRead: Bool = true,
                             message: String? = nil) {
        
        reader.startSession(with: message)
        if #available(iOS 13.0, *), runPreflightRead {
            preflightRead(environment: environment)
        } else {
            cardSessionDelegate.sessionDidStart(session: self,
                                                environment: environment,
                                                currentCard: nil)
        }
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
    
    /**
     * This method should be called by Tasks in their `sessionDidStart` method wherever
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
    
    @available(iOS 13.0, *)
    private func preflightRead(environment: CardEnvironment) {
        sendCommand(ReadCommand(), environment: environment) { [weak self] readResult in
            guard let self = self else { return }
            
            switch readResult {
            case .failure(let error):
                self.stopSession(error: error)
                self.cardSessionDelegate.sessionDidStart(session: self, environment: environment, currentCard: nil, error: error)
            case .success(let readResponse):
                if let expectedCardId = environment.cardId,
                    let actualCardId = readResponse.cardId,
                    expectedCardId != actualCardId {
                    let error = TaskError.wrongCard
                    self.stopSession(error: error)
                    self.cardSessionDelegate.sessionDidStart(session: self, environment: environment, currentCard: nil, error: error)
                    return
                }
                
                var newEnvironment = environment
                if newEnvironment.cardId == nil {
                    newEnvironment.cardId = readResponse.cardId
                }
                self.cardSessionDelegate.sessionDidStart(session: self, environment: newEnvironment, currentCard: readResponse, error: nil)
            }
        }
    }
}

public protocol CardSessionDelegate {
    func sessionDidStart(session: CardSession, environment: CardEnvironment, currentCard: Card?, error: TaskError?)
}
