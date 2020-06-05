//
//  CardSession.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CommonCrypto

public typealias CompletionResult<T> = (Result<T, TangemSdkError>) -> Void

/// Base protocol for run tasks in a card session
@available(iOS 13.0, *)
public protocol CardSessionRunnable {
    
    var needPreflightRead: Bool {get}
    /// Simple interface for responses received after sending commands to Tangem cards.
    associatedtype CommandResponse: ResponseCodable
    
    /// The starting point for custom business logic. Adopt this protocol and use `TangemSdk.startSession` to run
    /// - Parameters:
    ///   - session: You can run commands in this session
    ///   - completion: Call the completion handler to complete the task.
    func run(in session: CardSession, completion: @escaping CompletionResult<CommandResponse>)
}

@available(iOS 13.0, *)
extension CardSessionRunnable {
    public var needPreflightRead: Bool {
        return true
    }
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
    public internal(set) var environment: SessionEnvironment
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
    ///   - completion: Completion handler. `(Swift.Result<CardSessionRunnable.CommandResponse, TangemSdkError>) -> Void`
    public func start<T>(with runnable: T, completion: @escaping CompletionResult<T.CommandResponse>) where T : CardSessionRunnable {
        start(needPreflightRead: runnable.needPreflightRead) {[weak self] session, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            runnable.run(in: self) {result in
                self.handleRunnableCompletion(runnableResult: result, completion: completion)
            }
        }
    }
    
    /// Starts a card session and performs preflight `Read` command.
    /// - Parameter onSessionStarted: Delegate with the card session. Can contain error
    public func start(needPreflightRead: Bool = true, _ onSessionStarted: @escaping (CardSession, TangemSdkError?) -> Void) {
        guard TangemSdk.isNFCAvailable else {
            onSessionStarted(self, .unsupportedDevice)
            return
        }
        
        guard state == .inactive else {
            onSessionStarted(self, .busy)
            return
        }
        
        state = .active
        viewDelegate.sessionStarted()
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
                    onSessionStarted(self, error)
                }}, receiveValue: { [unowned self] tag in
                    self.viewDelegate.sessionStarted()
                    if case .tag = tag, needPreflightRead {
                        self.preflightCheck(onSessionStarted)
                    } else {
                        self.viewDelegate.sessionInitialized()
                        onSessionStarted(self, nil)
                    }
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
        viewDelegate.sessionStopped()
    }
    
    /// Stops the current session with the error message.  Error's `localizedDescription` will be used
    /// - Parameter error: The error to show
    public func stop(error: Error) {
        reader.stopSession(with: error.localizedDescription)
        state = .inactive
        connectedTagSubscription = []
        sendSubscription = []
        viewDelegate.sessionStopped()
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
            .flatMap { _ in self.establishEncryptionPublisher() }
            .flatMap { apdu.encryptPublisher(encryptionMode: self.environment.encryptionMode, encryptionKey: self.environment.encryptionKey) }
            .flatMap { self.reader.sendPublisher(apdu: $0) }
            .flatMap { $0.decryptPublisher(encryptionKey: self.environment.encryptionKey) }
            .sink(receiveCompletion: { readerCompletion in
                self.sendSubscription = []
                if case let .failure(error) = readerCompletion {
                    completion(.failure(error))
                }
            }, receiveValue: { responseApdu in
                print("receiveValue")
                self.sendSubscription = []
                completion(.success(responseApdu))
            })
            .store(in: &sendSubscription)
    }
    
    /// Perform read slix2 tags
    /// - Parameter completion: Completion handler. Invoked by nfc-reader
    public final func readSlix2Tag(completion: @escaping (Result<ResponseApdu, TangemSdkError>) -> Void)  {
        reader.readSlix2Tag(completion: completion)
    }
    
    private func handleRunnableCompletion<TResponse>(runnableResult: Result<TResponse, TangemSdkError>, completion: @escaping CompletionResult<TResponse>) {
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
    private func preflightCheck(_ onSessionStarted: @escaping (CardSession, TangemSdkError?) -> Void) {
        ReadCommand().run(in: self) { [weak self] readResult in
            guard let self = self else { return }
            
            switch readResult {
            case .success(let readResponse):
                if let expectedCardId = self.cardId?.uppercased(),
                    let actualCardId = readResponse.cardId?.uppercased() {
                    
                    var wrongCardError: TangemSdkError? = nil
                    
                    if expectedCardId != actualCardId {
                        wrongCardError = .wrongCardNumber
                    }
                    
                    if !self.environment.allowedCardTypes.contains(readResponse.cardType) {
                        wrongCardError = .wrongCardType
                    }
                    
                    if let wrongCardError = wrongCardError {
                        self.viewDelegate.wrongCard(message: wrongCardError.localizedDescription)
                        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                            self.restartPolling()
                            self.preflightCheck(onSessionStarted)
                        }
                        return
                    }
                }
                self.viewDelegate.sessionInitialized()
                onSessionStarted(self, nil)
            case .failure(let error):
                onSessionStarted(self, error)
                self.stop(error: error)
            }
        }
    }
    
    private func establishEncryptionPublisher() -> AnyPublisher<Void, TangemSdkError> {
        if self.environment.encryptionMode == .none || self.environment.encryptionKey != nil {
            return Just(()).setFailureType(to: TangemSdkError.self).eraseToAnyPublisher()
        }
        
        guard let encryptionHelper = EncryptionHelperFactory.make(for: self.environment.encryptionMode) else {
            return Fail(error: .cryptoUtilsError).eraseToAnyPublisher()
        }
        
        let openSessionCommand = OpenSessionCommand(sessionKeyA: encryptionHelper.keyA)
        let openSesssionApdu = try! openSessionCommand.serialize(with: self.environment)
        
        return reader
            .sendPublisher(apdu: openSesssionApdu)
            .flatMap { responseApdu -> AnyPublisher<Void, TangemSdkError> in
                let response = try! openSessionCommand.deserialize(with: self.environment, from: responseApdu)
                
                var uid: Data
                if let uidFromResponse = response.uid {
                    uid = uidFromResponse
                } else {
                    if case let .tag(tagUid) = self.connectedTag {
                        uid = tagUid
                    } else {
                        return Fail(error: .failedToEstablishEncryption).eraseToAnyPublisher()
                    }
                }
                
                guard let protocolKey = self.environment.pin1.pbkdf2sha256(salt: uid, rounds: 50),
                    let secret = encryptionHelper.generateSecret(keyB: response.sessionKeyB) else {
                        return Fail(error: .cryptoUtilsError).eraseToAnyPublisher()
                }
                
                let sessionKey = (secret + protocolKey).getSha256()
                self.environment.encryptionKey = sessionKey
                return Just(()).setFailureType(to: TangemSdkError.self).eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
}

//ed25519 from cryptokit?
