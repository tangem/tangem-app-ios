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
    associatedtype CommandResponse: TlvCodable
    
    /// The starting point for custom business logic. Adopt this protocol and use `TangemSdk.startSession` to run
    /// - Parameters:
    ///   - session: You can run commands in this session
    ///   - completion: Call the completion handler to complete the task.
    func run(in session: CardSession, completion: @escaping CompletionResult<CommandResponse>)
}

/// Allows interaction with Tangem cards. Should be open before sending commands
@available(iOS 13.0, *)
public class CardSession {
    /// Allows interaction with users and shows visual elements.
    public let viewDelegate: SessionViewDelegate
    
    /// Contains data relating to the current Tangem card. It is used in constructing all the commands,
    /// and commands can modify `SessionEnvironment`.
    public private(set) var environment: SessionEnvironment
    
    /// True when some operation is still in progress.
    public private(set) var isBusy = false
    
    private let reader: CardReader
    private let semaphore = DispatchSemaphore(value: 1)
    private let initialMessage: String?
    private var cardId: String?
    private var sendSubscription: [AnyCancellable] = []
    private var connectedTagSubscription: [AnyCancellable] = []
    private var runnableDelegate: ((CardSession, SessionError?) -> Void)?
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
            
            if (runnable is ReadCommand) && self.environment.card != nil { //We already done ReadCommand on iOS 13 for cards
                self.handleRunnableCompletion(runnableResult: .success(self.environment.card as! T.CommandResponse), completion: completion)
                return
            }
            
            runnable.run(in: self) {result in
                self.handleRunnableCompletion(runnableResult: result, completion: completion)
            }
        }
    }
    
    /// Starts a card session and performs preflight `Read` command.
    /// - Parameter delegate: Delegate with the card session. Can contain error
    public func start(delegate: @escaping (CardSession, SessionError?) -> Void) {
        do {
            try startSession()
            runnableDelegate = delegate
        } catch {
            delegate(self, error as? SessionError)
        }
    }
    
    /// Stops the current session with the text message. If nil, the default message will be shown
    /// - Parameter message: The message to show
    public func stop(message: String? = nil) {
        if let message = message {
            viewDelegate.showAlertMessage(message)
        }
        reader.stopSession()
        setBusy(false)
        connectedTagSubscription = []
        sendSubscription = []
        runnableDelegate = nil
    }
    
    /// Stops the current session with the error message.  Error's `localizedDescription` will be used
    /// - Parameter error: The error to show
    public func stop(error: Error) {
        reader.stopSession(with: error.localizedDescription)
        setBusy(false)
        connectedTagSubscription = []
        sendSubscription = []
        runnableDelegate = nil
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
        reader.tagConnected
            .compactMap({ $0 })
            .sink(receiveCompletion: { readerCompletion in
                if case let .failure(error) = readerCompletion {
                    completion(.failure(error))
                }
            }, receiveValue: { [weak self] tag in
                switch tag {
                case .tag:
                    //openSession if environment.encryptionKey is nil
                    self?.reader.send(apdu: apdu) { [weak self] result in
                        self?.sendSubscription = []
                        completion(result)
                    }
                case .slix2:
                    self?.reader.readSlix2Tag() { [weak self] result in
                        self?.sendSubscription = []
                        completion(result)
                    }
                case .unknown:
                    assertionFailure("Unsupported tag")
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
    
    private func startSession() throws {
        guard TangemSdk.isNFCAvailable else {
            throw SessionError.unsupportedDevice
        }
        
        if isBusy { throw SessionError.busy }
        setBusy(true)
        
        reader.tagConnected
            .dropFirst()
            .sink(receiveCompletion: { [weak self] readerCompletion in
                guard let self = self else { return }
                
                if case let .failure(error) = readerCompletion, !self.reader.isReady {
                    self.runnableDelegate?(self, error)
                    self.stop(error: error)
                }
                }, receiveValue: { [weak self] tag in
                    guard let self = self else { return }
                    
                    if let tag = tag {
                        self.viewDelegate.tagConnected()
                        if tag == .tag && self.environment.card == nil  {
                            self.preflightCheck() { [weak self] result in
                                guard let self = self else { return }
                                
                                switch result {
                                case .success:
                                    self.runnableDelegate?(self, nil)
                                case .failure(let error):
                                    self.runnableDelegate?(self, error)
                                    self.stop(error: error)
                                }
                            }
                        }
                    } else {
                        self.environment.encryptionKey = nil
                        self.viewDelegate.tagLost()
                    }
            })
            .store(in: &connectedTagSubscription)
        
        reader.startSession(with: initialMessage)
    }
    
    private func setBusy(_ isBusy: Bool) {
        semaphore.wait()
        defer { semaphore.signal() }
        self.isBusy = isBusy
    }
    
    @available(iOS 13.0, *)
    private func preflightCheck(completion: @escaping CompletionResult<ReadResponse>) {
        let readCommand = ReadCommand()
        readCommand.run(in: self) { [weak self] readResult in
            guard let self = self else { return }
            
            switch readResult {
            case .success(let readResponse):
                if let expectedCardId = self.cardId?.uppercased(),
                    let actualCardId = readResponse.cardId?.uppercased(),
                    expectedCardId != actualCardId {
                    let error = SessionError.wrongCard
                    completion(.failure(error))
                    return
                }
                
                self.environment.card = readResponse
                self.cardId = readResponse.cardId
                completion(.success(readResponse))
            case .failure(let error):
                if !self.tryHandleError(error) {
                    completion(.failure(error))
                }
            }
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
