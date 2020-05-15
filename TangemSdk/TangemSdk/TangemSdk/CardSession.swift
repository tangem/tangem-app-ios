//
//  CardSession.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public typealias CompletionResult<T> = (Result<T, SessionError>) -> Void

/// Base protocol for run tasks in a card session
@available(iOS 13.0, *)
public protocol CardSessionRunnable {
    
    /// Simple interface for responses received after sending commands to Tangem cards.
    associatedtype CommandResponse: ResponseCodable
    
    /// The starting point for custom business logic. Adopt this protocol and use `TangemSdk.startSession` to run
    /// - Parameters:
    ///   - session: You can run commands in this session
    ///   - completion: Call the completion handler to complete the task.
    func run(in session: CardSession, completion: @escaping CompletionResult<CommandResponse>)
}

/// Allows interaction with Tangem cards. Should be open before sending commands
@available(iOS 13.0, *)
public class CardSession {
    enum CardSessionState {
        case inactive
        case active
    }
    /// Allows interaction with users and shows visual elements.
    public let viewDelegate: SessionViewDelegate
    
    /// Contains data relating to the current Tangem card. It is used in constructing all the commands,
    /// and commands can modify `SessionEnvironment`.
    public private(set) var environment: SessionEnvironment
    public private(set) var connectedTag: NFCTagType? = nil
    
    private let reader: CardReader
    private let initialMessage: String?
    private let cardId: String?
    private var sendSubscription: [AnyCancellable] = []
    private var connectedTagSubscription: [AnyCancellable] = []
    private var state: CardSessionState = .inactive
    /// Main initializer
    /// - Parameters:
    ///   - environment: Contains data relating to a Tangem card
    ///   - cardId: CID, Unique Tangem card ID number. If not nil, the SDK will check that you tapped the  card with this cardID and will return the `wrongCard` error' otherwise
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - cardReader: NFC-reader implementation
    ///   - viewDelegate: viewDelegate implementation
    public init(environment: SessionEnvironment, cardId: String? = nil, initialMessage: String? = nil, cardReader: CardReader, viewDelegate: SessionViewDelegate) {
        self.reader = cardReader
        self.viewDelegate = viewDelegate
        self.environment = environment
        self.initialMessage = initialMessage
        self.cardId = cardId
    }
    
    deinit {
        print ("Card session deinit")
    }
    
    /// This metod starts a card session, performs preflight `Read` command,  invokes the `run ` method of `CardSessionRunnable` and closes the session.
    /// - Parameters:
    ///   - runnable: The CardSessionRunnable implemetation
    ///   - completion: Completion handler. `(Swift.Result<CardSessionRunnable.CommandResponse, SessionError>) -> Void`
    public func start<T>(with runnable: T, completion: @escaping CompletionResult<T.CommandResponse>) where T : CardSessionRunnable {
        start {[weak self] session, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            if (runnable is ReadCommand) { //We already done ReadCommand on iOS 13 for cards
                self.handleRunnableCompletion(runnableResult: .success(self.environment.card as! T.CommandResponse), completion: completion)
                return
            }
            
            runnable.run(in: self) {result in
                self.handleRunnableCompletion(runnableResult: result, completion: completion)
            }
        }
    }
    
    /// Starts a card session and performs preflight `Read` command.
    /// - Parameter callback: Delegate with the card session. Can contain error
    public func start(_ callback: @escaping (CardSession, SessionError?) -> Void) {
        guard TangemSdk.isNFCAvailable else {
            callback(self, .unsupportedDevice)
            return
        }
        
        guard state == .inactive else {
            callback(self, .busy)
            return
        }
        
        state = .active
        
        reader.tag //Subscription for handle tag lost/connected events
            .dropFirst()
            .sink(receiveCompletion: {_ in},
                  receiveValue: {[unowned self] tag in
                    if tag != nil {
                        self.connectedTag = tag
                        self.viewDelegate.tagConnected()
                    } else {
                        self.connectedTag = nil
                        self.environment.encryptionKey = nil
                        self.viewDelegate.tagLost()
                    }
            })
            .store(in: &connectedTagSubscription)
        
        reader.tag //Subscription for session initialization and handling any error before session is activated
            .compactMap{ $0 }
            .first()
            .sink(receiveCompletion: { [unowned self] readerCompletion in
                if case let .failure(error) = readerCompletion {
                    self.stop(error: error)
                    callback(self, error)
                }}, receiveValue: { [unowned self] tag in
                    self.initializeSession(tag, callback)
            })
            .store(in: &connectedTagSubscription)
        
        reader.startSession(with: initialMessage)
    }
    
    /// Stops the current session with the text message. If nil, the default message will be shown
    /// - Parameter message: The message to show
    public func stop(message: String? = nil) {
        if let message = message {
            viewDelegate.showAlertMessage(message)
        }
        reader.stopSession()
        state = .inactive
        connectedTagSubscription = []
        sendSubscription = []
    }
    
    /// Stops the current session with the error message.  Error's `localizedDescription` will be used
    /// - Parameter error: The error to show
    public func stop(error: Error) {
        reader.stopSession(with: error.localizedDescription)
        state = .inactive
        connectedTagSubscription = []
        sendSubscription = []
    }
    
    /// Restarts the polling sequence so the reader session can discover new tags.
    public func restartPolling() {
        reader.restartPolling()
    }
    
    /// Sends `CommandApdu` to the current card
    /// - Parameters:
    ///   - apdu: The apdu to send
    ///   - completion: Completion handler. Invoked by nfc-reader
    public final func send(apdu: CommandApdu, completion: @escaping CompletionResult<ResponseApdu>) {
        guard sendSubscription.isEmpty else {
            completion(.failure(.busy))
            return
        }
        
        guard state == .active else {
            completion(.failure(.sessionInactive))
            return
        }
        
        reader.tag
            .compactMap{ $0 }
            .sink(receiveCompletion: { [weak self] readerCompletion in
                if case let .failure(error) = readerCompletion {
                    self?.sendSubscription = []
                    completion(.failure(error))
                }
            }, receiveValue: { [unowned self] _ in
                self.reader.send(apdu: apdu) { [weak self] result in
                    self?.sendSubscription = []
                    completion(result)
                }
            })
            .store(in: &sendSubscription)
    }
    
    private func handleRunnableCompletion<TResponse>(runnableResult: Result<TResponse, SessionError>, completion: @escaping CompletionResult<TResponse>) {
        switch runnableResult {
        case .success(let runnableResponse):
            stop(message: Localization.nfcAlertDefaultDone)
            DispatchQueue.main.async { completion(.success(runnableResponse)) }
        case .failure(let error):
            stop(error: error)
            DispatchQueue.main.async { completion(.failure(error)) }
        }
    }
    
    @available(iOS 13.0, *)
    private func initializeSession(_ tagType: NFCTagType, _ callback: @escaping (CardSession, SessionError?) -> Void) {
        switch tagType {
        case .tag:
            ReadCommand().run(in: self) { [weak self] readResult in
                guard let self = self else { return }
                
                switch readResult {
                case .success(let readResponse):
                    if let expectedCardId = self.cardId?.uppercased(),
                        let actualCardId = readResponse.cardId?.uppercased(),
                        expectedCardId != actualCardId {
                        let error = SessionError.wrongCard
                        callback(self, error)
                        self.stop(error: error)
                        return
                    }
                    
                    self.environment.card = readResponse
                    callback(self, nil)
                case .failure(let error):
                    if !self.tryHandleError(error) {
                        callback(self, error)
                        self.stop(error: error)
                    }
                }
            }
        case .slix2:
            self.reader.readSlix2Tag() {[weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let responseApdu):
                    do {
                        self.environment.card = try CardDeserializer.deserialize(with: self.environment, from: responseApdu)
                        self.stop()
                        callback(self, nil)
                    } catch {
                        let sessionError = error.toSessionError()
                        self.stop(error: sessionError)
                        callback(self, sessionError)
                    }
                case .failure(let error):
                    self.stop(error: error)
                    callback(self, error)
                }
            }
        default:
            assertionFailure("Unsupported tag")
            callback(self, .unknownError)
        }
    }
    
    private func tryHandleError(_ error: SessionError) -> Bool {
        switch error {
        case .needEncryption:
            //[REDACTED_TODO_COMMENT]
            return false
        default:
            return false
        }
    }
}
