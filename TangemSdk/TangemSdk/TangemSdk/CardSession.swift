//
//  CardSession.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public typealias CompletionResult<T> = (Result<T, SessionError>) -> Void

public protocol AnyCardSessionRunnable {}

/// Abstract class for all Tangem card commands.
public protocol CardSessionRunnable: AnyCardSessionRunnable {
    /// Simple interface for responses received after sending commands to Tangem cards.
    associatedtype CommandResponse: TlvCodable
    func run(in session: CardSession, completion: @escaping CompletionResult<CommandResponse>)
}

public class CardSession {
    public let viewDelegate: CardSessionViewDelegate
    public private(set) var environment: CardEnvironment

    private let reader: CardReader
    private let semaphore = DispatchSemaphore(value: 1)
    private let initialMessage: String?
    private var currentRunnable: AnyCardSessionRunnable? = nil
    private var cardId: String?
    
    private var isBusy: Bool {
        semaphore.wait()
        defer { semaphore.signal() }
        return currentRunnable != nil || reader.isReady
    }

    public init(environment: CardEnvironment, cardId: String? = nil, initialMessage: String? = nil, cardReader: CardReader, viewDelegate: CardSessionViewDelegate) {
        self.reader = cardReader
        self.viewDelegate = viewDelegate
        self.environment = environment
        self.initialMessage = initialMessage
        self.cardId = cardId
    }
    
    public func start<T>(with runnable: T, completion: @escaping CompletionResult<T.CommandResponse>) where T : CardSessionRunnable {
        start {[weak self] session, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if #available(iOS 13.0, *), (runnable is ReadCommand) { //We already done ReadCommand on iOS 13
                completion(.success(self.environment.card as! T.CommandResponse))
                return
            }
            
            self.retainRunnable(runnable)
            runnable.run(in: self) { [weak self] result in
                self?.handleRunnableCompletion(runnableResult: result, completion: completion)
            }
        }
    }
    
    private var curdel: ((CardSession, SessionError?) -> Void)?
    
    public func start(delegate: @escaping (CardSession, SessionError?) -> Void) {
        if let error = startSession() {
            delegate(self, error)
            return
        }
        curdel = delegate
        if #available(iOS 13.0, *) {
            preflightRead() {[weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let preflightResponse):
                    self.environment.card = preflightResponse
                    delegate(self, nil)
                case .failure(let error):
                    delegate(self, error)
                    self.stop(error: error)
                }
            }
        } else {
            delegate(self, nil)
        }
    }
    
    public func stop(message: String? = nil) {
        if let message = message {
            viewDelegate.showAlertMessage(message)
        }
        reader.stopSession()
    }
    
    public func stop(error: Error) {
        reader.stopSession(with: error.localizedDescription)
    }
    
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
                    
                    completion(.failure(SessionError.needEncryption))
                    
                case .invalidParams:
                    //[REDACTED_TODO_COMMENT]
                    
                    completion(.failure(SessionError.invalidParams))
                    
                case .processCompleted, .pin1Changed, .pin2Changed, .pin3Changed:
                    completion(.success(responseApdu))
                case .errorProcessingCommand:
                    completion(.failure(SessionError.errorProcessingCommand))
                case .invalidState:
                    completion(.failure(SessionError.invalidState))
                    
                case .insNotSupported:
                    completion(.failure(SessionError.insNotSupported))
                case .unknown:
                    print("Unknown sw: \(responseApdu.sw)")
                    completion(.failure(SessionError.unknownStatus))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Helper method to parse security delay information received from a card.
    /// - Returns: Remaining security delay in milliseconds.
    private func deserializeSecurityDelay(with environment: CardEnvironment, from responseApdu: ResponseApdu) -> (remainingMilliseconds: Int, saveToFlash: Bool)? {
        guard let tlv = responseApdu.getTlvData(encryptionKey: environment.encryptionKey),
            let remainingMilliseconds = tlv.value(for: .pause)?.toInt() else {
                return nil
        }
        
        let saveToFlash = tlv.contains(tag: .flash)
        return (remainingMilliseconds, saveToFlash)
    }
    
    private func handleRunnableCompletion<TResponse>(runnableResult: Result<TResponse, SessionError>, completion: @escaping CompletionResult<TResponse>) {
        switch runnableResult {
        case .success(let runnableResponse):
            DispatchQueue.main.async {
                completion(.success(runnableResponse))
            }
            self.completeRunnable()
        case .failure(let error):
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            self.completeRunnable(error: error)
        }
    }
    
    private func startSession() -> SessionError? {
        guard TangemSdk.isNFCAvailable else {
            return .unsupportedDevice
        }
        
        if isBusy { return .busy }
        reader.startSession(with: initialMessage)        
        return nil
    }
    
    private func completeRunnable(error: Error? = nil) {
        releaseRunnable()
        if let error = error {
            self.stop(error: error)
        } else {
            self.stop(message: Localization.nfcAlertDefaultDone)
        }
    }
    
    private func retainRunnable(_ runnable: AnyCardSessionRunnable) {
        semaphore.wait()
        defer { semaphore.signal() }
        currentRunnable = runnable
    }
    
    private func releaseRunnable( ) {
        semaphore.wait()
        defer { semaphore.signal() }
        currentRunnable = nil
    }
    
    @available(iOS 13.0, *)
    private func preflightRead(completion: @escaping CompletionResult<ReadResponse>) {
        let readCommand = ReadCommand()
        retainRunnable(readCommand)
        readCommand.run(in: self) { [weak self] readResult in
            guard let self = self else { return }
            
            switch readResult {
            case .failure(let error):
                self.stop(error: error)
                completion(.failure(error))
            case .success(let readResponse):
                if let expectedCardId = self.cardId,
                    let actualCardId = readResponse.cardId,
                    expectedCardId != actualCardId {
                    let error = SessionError.wrongCard
                    self.stop(error: error)
                    completion(.failure(error))
                    return
                }
                
                self.environment.card = readResponse
                self.cardId = readResponse.cardId
                self.releaseRunnable()
                completion(.success(readResponse))
            }
        }
    }
}

extension CardSession{
    public convenience init(environment: CardEnvironment, cardId: String? = nil, initialMessage: String? = nil) {
        let reader = CardReaderFactory().createDefaultReader()
        let delegate = DefaultCardSessionViewDelegate(reader: reader)
        self.init(environment: environment, cardId: cardId, initialMessage: initialMessage, cardReader: reader, viewDelegate: delegate)
    }
}
