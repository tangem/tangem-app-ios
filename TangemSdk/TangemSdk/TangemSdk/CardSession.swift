//
//  CardSession.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public typealias CompletionResult<T> = (Result<T, SessionError>) -> Void

/// Abstract class for all Tangem card commands.
public protocol CardSessionRunnable {
    /// Simple interface for responses received after sending commands to Tangem cards.
    associatedtype CommandResponse: TlvCodable
    func run(in session: CardSession, completion: @escaping CompletionResult<CommandResponse>)
}

public class CardSession {
    public let viewDelegate: CardSessionViewDelegate
    public private(set) var environment: CardEnvironment
    public private(set) var isBusy = false
    
    private let reader: CardReader
    private let semaphore = DispatchSemaphore(value: 1)
    private let initialMessage: String?
    private var cardId: String?

    public init(environment: CardEnvironment, cardId: String? = nil, initialMessage: String? = nil, cardReader: CardReader, viewDelegate: CardSessionViewDelegate) {
        self.reader = cardReader
        self.viewDelegate = viewDelegate
        self.environment = environment
        self.initialMessage = initialMessage
        self.cardId = cardId
    }
    
    deinit {
        print ("Card session deinit")
    }
    
    public func start<T>(with runnable: T, completion: @escaping CompletionResult<T.CommandResponse>) where T : CardSessionRunnable {
        start {session, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            if #available(iOS 13.0, *), (runnable is ReadCommand) { //We already done ReadCommand on iOS 13
                self.handleRunnableCompletion(runnableResult: .success(self.environment.card as! T.CommandResponse), completion: completion)
                return
            }
            
            runnable.run(in: self) {result in
                self.handleRunnableCompletion(runnableResult: result, completion: completion)
            }
        }
    }
    
    public func start(delegate: @escaping (CardSession, SessionError?) -> Void) {
        if let error = startSession() {
            delegate(self, error)
            return
        }
        if #available(iOS 13.0, *) {
            preflightRead() {result in
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
        setBusy(false)
    }
    
    public func stop(error: Error) {
        reader.stopSession(with: error.localizedDescription)
        setBusy(false)
    }
    
    public func restartPolling() {
        reader.restartPolling()
    }
    
    public final func send(apdu: CommandApdu, completion: @escaping CompletionResult<ResponseApdu>) {
        reader.send(commandApdu: apdu) {commandResponse in
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
        setBusy(true)
        
        reader.startSession(with: initialMessage)        
        return nil
    }
    
    private func completeRunnable(error: Error? = nil) {
        setBusy(false)
        if let error = error {
            self.stop(error: error)
        } else {
            self.stop(message: Localization.nfcAlertDefaultDone)
        }
    }
    
    private func setBusy(_ isBusy: Bool) {
        semaphore.wait()
        defer { semaphore.signal() }
        self.isBusy = isBusy
    }
    
    @available(iOS 13.0, *)
    private func preflightRead(completion: @escaping CompletionResult<ReadResponse>) {
        let readCommand = ReadCommand()
        readCommand.run(in: self) { readResult in
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
