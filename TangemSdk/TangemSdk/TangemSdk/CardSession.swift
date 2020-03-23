//
//  CardSession.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public typealias CompletionResult<T> = (Result<T, TaskError>) -> Void

public protocol TangemCardSession {
    func stopSession(message: String?)
    func stopSession(error: Error)
    func run<T: Command>(_ command: T, sessionParams: CardSessionParams, completion: @escaping CompletionResult<T.CommandResponse>)
    
    @available(iOS 13.0, *)
    func run<T: PreflightCommand>(_ command: T, sessionParams: CardSessionParams, completion: @escaping CompletionResult<T.CommandResponse>)
}

public protocol CommandTransiever {
    func sendCommand<T: SerializableCommand>(_ command: T, environment: CardEnvironment, completion: @escaping CompletionResult<T.CommandResponse>)
    func sendApdu(_ apdu: CommandApdu, environment: CardEnvironment, completion: @escaping CompletionResult<ResponseApdu>)
}

public struct CardSessionParams {
    public var environment: CardEnvironment = CardEnvironment()
    public var initialMessage: String? = nil
    public var stopSession: Bool = true
}


public class CardSession: TangemCardSession {
    private let reader: CardReader
    private let viewDelegate: CardManagerDelegate
    private var currentCommand: AnyCommand?
    private var isBusy: Bool = false
    private var sessionParams: CardSessionParams!
    
    public init(reader: CardReader, viewDelegate: CardManagerDelegate) {
        self.reader = reader
        self.viewDelegate = viewDelegate
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
    
    
    @available(iOS 13.0, *)
    public func run<T: PreflightCommand>(_ command: T, sessionParams: CardSessionParams, completion: @escaping CompletionResult<T.CommandResponse>) {
        if let error = startCommand(command, sessionParams: sessionParams) {
            completion(.failure(error))
            return
        }
        
        preflightRead(environment: sessionParams.environment) {[unowned self] result in
            switch result {
            case .success(let card):
                command.run(session: self, environment: sessionParams.environment, currentCard: card, completion: { [unowned self] result in
                    self.handleCommandCompletion(commandResult: result, completion: completion)
                })
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                self.completeCommand(stopSession: true)
            }
        }
    }
    
    public func run<T: Command>(_ command: T, sessionParams: CardSessionParams, completion: @escaping CompletionResult<T.CommandResponse>) {
        if let error = startCommand(command, sessionParams: sessionParams) {
            completion(.failure(error))
            return
        }
        
        command.run(session: self, environment: sessionParams.environment, completion: { [unowned self] result in
            self.handleCommandCompletion(commandResult: result, completion: completion)
        })
    }
    
    private func handleCommandCompletion<TResponse>(commandResult: Result<TResponse, TaskError>, completion: @escaping CompletionResult<TResponse>) {
        switch commandResult {
        case .success(let commandResponse):
            DispatchQueue.main.async {
                completion(.success(commandResponse))
            }
            self.completeCommand(stopSession: self.sessionParams.stopSession)
        case .failure(let error):
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            self.completeCommand(stopSession: true)
        }
    }
    
    private func startCommand(_ command: AnyCommand, sessionParams: CardSessionParams) -> TaskError? {
        guard CardManager.isNFCAvailable else {
            return .unsupportedDevice
        }
        
        guard !isBusy else {
            return .busy
        }
        
        self.sessionParams = sessionParams
        currentCommand = command
        isBusy = true
        
        //[REDACTED_TODO_COMMENT]
        reader.startSession(with: sessionParams.initialMessage)
        return nil
    }
    
    
    private func completeCommand(stopSession: Bool) {
        self.isBusy = false
        self.currentCommand = nil
        if sessionParams.stopSession {
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
    public final func sendCommand<T: SerializableCommand>(_ command: T, environment: CardEnvironment, completion: @escaping CompletionResult<T.CommandResponse>) {
        do {
            let commandApdu = try command.serialize(with: environment)
            sendApdu(commandApdu, environment: environment) { result in
                switch result {
                case .success(let responseApdu):
                    do {
                        let responseData = try command.deserialize(with: environment, from: responseApdu)
                        completion(.success(responseData))
                    } catch {
                        completion(.failure(error.toTaskError()))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(error.toTaskError()))
        }
    }
    
    public final func sendApdu(_ apdu: CommandApdu, environment: CardEnvironment, completion: @escaping CompletionResult<ResponseApdu>) {
        reader.send(commandApdu: apdu) { [weak self] commandResponse in
            switch commandResponse {
            case .success(let responseApdu):
                switch responseApdu.statusWord {
                case .needPause:
                    if let securityDelayResponse = self?.deserializeSecurityDelay(with: environment, from: responseApdu) {
                        self?.viewDelegate.showSecurityDelay(remainingMilliseconds: securityDelayResponse.remainingMilliseconds)
                        if securityDelayResponse.saveToFlash {
                            self?.reader.restartPolling()
                        }
                    }
                    self?.sendApdu(apdu, environment: environment, completion: completion)
                case .needEcryption:
                    //[REDACTED_TODO_COMMENT]
                    
                    completion(.failure(TaskError.needEncryption))
                    
                case .invalidParams:
                    //[REDACTED_TODO_COMMENT]
                    
                    completion(.failure(TaskError.invalidParams))
                    
                case .processCompleted, .pin1Changed, .pin2Changed, .pin3Changed:
                    completion(.success(responseApdu))
                case .errorProcessingCommand:
                    completion(.failure(TaskError.errorProcessingCommand))
                case .invalidState:
                    completion(.failure(TaskError.invalidState))
                    
                case .insNotSupported:
                    completion(.failure(TaskError.insNotSupported))
                case .unknown:
                    print("Unknown sw: \(responseApdu.sw)")
                    completion(.failure(TaskError.unknownStatus))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

extension CardSession {
    /// Helper method to parse security delay information received from a card.
    /// - Returns: Remaining security delay in milliseconds.
    func deserializeSecurityDelay(with environment: CardEnvironment, from responseApdu: ResponseApdu) -> (remainingMilliseconds: Int, saveToFlash: Bool)? {
        guard let tlv = responseApdu.getTlvData(encryptionKey: environment.encryptionKey),
            let remainingMilliseconds = tlv.value(for: .pause)?.toInt() else {
                return nil
        }
        
        let saveToFlash = tlv.contains(tag: .flash)
        return (remainingMilliseconds, saveToFlash)
    }
}
