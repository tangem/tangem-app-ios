//
//  CardSession.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public typealias CompletionResult<T> = (Result<T, TaskError>) -> Void

public protocol CardSession {
    func stopSession(message: String?)
    func stopSession(error: Error)
    func runInSession<T: CardSessionRunnable>(command: T, completion: @escaping CompletionResult<T.CommandResponse>)
    @available(iOS 13.0, *)
    func runInSession(delegate: @escaping (_ session: CommandTransiever, _ currentCard: Card, _ error: TaskError?) -> Void)
}

public protocol CommandTransiever {
    var viewDelegate: CardManagerDelegate { get }
    var environment: CardEnvironment { get set }
    //func send<T: CardSessionRunnable>(command: T, completion: @escaping CompletionResult<T.CommandResponse>)
    func send(apdu: CommandApdu, completion: @escaping CompletionResult<ResponseApdu>)
}

public class TangemCardSession {
    public var initialMessage: String? = nil
    public var config = Config()
    public var environment: CardEnvironment = CardEnvironment()
    public let viewDelegate: CardManagerDelegate
    
    private let reader: CardReader
    private let semaphore = DispatchSemaphore(value: 1)
    private let storageService = SecureStorageService()
    private var currentCommand: AnyCardSessionRunnable? = nil
    private var cardId: String?
    
    private lazy var terminalKeysService: TerminalKeysService = {
        let service = TerminalKeysService(secureStorageService: storageService)
        return service
    }()
    
    private var isBusy: Bool {
        semaphore.wait()
        defer { semaphore.signal() }
        return currentCommand != nil
    }
    
    public init(cardId: String?, cardReader: CardReader, viewDelegate: CardManagerDelegate) {
        self.reader = cardReader
        self.viewDelegate = viewDelegate
        self.cardId = cardId
    }
    
    //    public func run<T: CardSessionRunnable>(_ command: T, sessionParams: CardSessionParams, completion: @escaping CompletionResult<T.CommandResponse>) {
    //        if let error = startCommand(command, sessionParams: sessionParams) {
    //            completion(.failure(error))
    //            return
    //        }
    //
    //        if #available(iOS 13.0, *), sessionParams.environment.cardId != nil {
    //            preflightRead(environment: sessionParams.environment) {[unowned self] result in
    //                switch result {
    //                case .success(let preflightResponse):
    //                    command.run(session: self, viewDelegate: self.viewDelegate, environment: preflightResponse.environment, completion: { [unowned self] result in
    //                        self.handleCommandCompletion(commandResult: result, completion: completion)
    //                    })
    //                case .failure(let error):
    //                    DispatchQueue.main.async {
    //                        completion(.failure(error))
    //                    }
    //                    self.completeCommand(stopSession: true, error: error)
    //                }
    //            }
    //        } else {
    //            command.run(session: self, viewDelegate: self.viewDelegate, environment: sessionParams.environment, completion: { [unowned self] result in
    //                self.handleCommandCompletion(commandResult: result, completion: completion)
    //            })
    //        }
    //    }
    
    private func handleCommandCompletion<TResponse>(commandResult: Result<TResponse, TaskError>, completion: @escaping CompletionResult<TResponse>) {
        switch commandResult {
        case .success(let commandResponse):
            DispatchQueue.main.async {
                completion(.success(commandResponse))
            }
            self.completeCommand()
        case .failure(let error):
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            self.completeCommand(error: error)
        }
    }
    
    private func startSession() -> TaskError? {
        guard TangemSdk.isNFCAvailable else {
            return .unsupportedDevice
        }
        
        if isBusy { return .busy }
        
        if !reader.isReady {
            reader.startSession(with: initialMessage)
        }
        
        environment = prepareCardEnvironment(for: cardId)
        return nil
    }
    
    private func completeCommand(error: Error? = nil) {
        releaseCommand()
        if let error = error {
            self.stopSession(error: error)
        } else {
            self.stopSession(message: Localization.nfcAlertDefaultDone)
        }
    }
    
    private func retainCommand(_ command: AnyCardSessionRunnable) {
        semaphore.wait()
        defer { semaphore.signal() }
        currentCommand = command
    }
    
    private func releaseCommand( ) {
        semaphore.wait()
        defer { semaphore.signal() }
        currentCommand = nil
    }
    
    private func prepareCardEnvironment(for cardId: String? = nil) -> CardEnvironment {
        let isLegacyMode = config.legacyMode ?? NfcUtils.isLegacyDevice
        var environment = CardEnvironment()
        environment.cardId = cardId
        environment.legacyMode = isLegacyMode
        if config.linkedTerminal && !isLegacyMode {
            environment.terminalKeys = terminalKeysService.getKeys()
        }
        return environment
    }
    
    @available(iOS 13.0, *)
    private func preflightRead(completion: @escaping CompletionResult<ReadResponse>) {
        let readCommand = ReadCommand()
        readCommand.sendCommand(transiever: self) { [weak self] readResult in
            guard let self = self else { return }
            
            switch readResult {
            case .failure(let error):
                self.stopSession(error: error)
                completion(.failure(error))
            case .success(let readResponse):
                if let expectedCardId = self.environment.cardId,
                    let actualCardId = readResponse.cardId,
                    expectedCardId != actualCardId {
                    let error = TaskError.wrongCard
                    self.stopSession(error: error)
                    completion(.failure(error))
                    return
                }
                
                if self.environment.cardId == nil {
                    self.environment.cardId = readResponse.cardId
                }
                
                completion(.success(readResponse))
            }
        }
    }
}


extension TangemCardSession: CardSession {
    public func stopSession(message: String? = nil) {
        if let message = message {
            viewDelegate.showAlertMessage(message)
        }
        reader.stopSession()
    }
    
    public func stopSession(error: Error) {
        reader.stopSession(with: error.localizedDescription)
    }
    
    public func runInSession<T>(command: T, completion: @escaping CompletionResult<T.CommandResponse>) where T : CardSessionRunnable {
        if let error = startSession() {
            completion(.failure(error))
            return
        }
        
        retainCommand(command)
        
        if #available(iOS 13.0, *), !(command is ReadCommand) {
            preflightRead() {[weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let preflightResponse):
                    command.run(session: self, currentCard: preflightResponse, completion: { [weak self] result in
                        self?.handleCommandCompletion(commandResult: result, completion: completion)
                    })
                case .failure(let error):
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    self.completeCommand(error: error)
                }
            }
        } else {
            command.run(session: self, currentCard: Card(), completion: { [weak self] result in
                self?.handleCommandCompletion(commandResult: result, completion: completion)
            })
        }
    }
    
    @available(iOS 13.0, *)
    public func runInSession(delegate: @escaping (CommandTransiever, Card, TaskError?) -> Void) {
        if let error = startSession() {
            delegate(self, Card(), error)
            return
        }
        
        preflightRead() {[weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let preflightResponse):
                delegate(self, preflightResponse, nil)
            case .failure(let error):
                delegate(self, Card(), error)
                self.stopSession(error: error)
            }
        }
    }
    
}

extension TangemCardSession: CommandTransiever {
    public final func send(apdu: CommandApdu, completion: @escaping CompletionResult<ResponseApdu>) {
        reader.send(commandApdu: apdu) { [weak self] commandResponse in
            guard let self = self else { return }
            
            switch commandResponse {
            case .success(let responseApdu):
                switch responseApdu.statusWord {
                case .needPause:
                    if let securityDelayResponse = self.deserializeSecurityDelay(with: self.environment, from: responseApdu) {
                        self.viewDelegate.showSecurityDelay(remainingMilliseconds: securityDelayResponse.remainingMilliseconds)
                        if securityDelayResponse.saveToFlash {
                            self.reader.restartPolling()
                        }
                    }
                    self.send(apdu: apdu, completion: completion)
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

extension TangemCardSession {
    public convenience init(cardId: String? = nil) {
        let reader = CardReaderFactory().createDefaultReader()
        let delegate = DefaultCardManagerDelegate(reader: reader)
        self.init(cardId: cardId, cardReader: reader, viewDelegate: delegate)
    }
}
