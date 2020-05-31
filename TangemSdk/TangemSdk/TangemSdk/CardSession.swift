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

public typealias CompletionResult<T> = (Result<T, SessionError>) -> Void

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
    ///   - completion: Completion handler. `(Swift.Result<CardSessionRunnable.CommandResponse, SessionError>) -> Void`
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
    public func start(needPreflightRead: Bool = true, _ onSessionStarted: @escaping (CardSession, SessionError?) -> Void) {
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
            .compactMap{ _ in }
            .flatMap { self.sendInternalCombine(apdu: apdu) }
            .sink(receiveCompletion: { readerCompletion in
                self.sendSubscription = []
                if case let .failure(error) = readerCompletion {
                    completion(.failure(error))
                }
            }, receiveValue: { responseApdu in
                self.sendSubscription = []
                completion(.success(responseApdu))
            })
            .store(in: &sendSubscription)
    }
    
    private func sendInternalCombine(apdu: CommandApdu) -> Future<ResponseApdu,SessionError> {
        let future = Future<ResponseApdu,SessionError> { promise in
            self.sendInternal(apdu: apdu, completion: promise)
        }
        return future
    }
    
    private func sendInternal(apdu: CommandApdu, completion: @escaping (Result<ResponseApdu,SessionError>) -> Void) {
        print("sendInternal: \(Instruction(rawValue: apdu.ins)!)")
        guard let apduEncrypted = try? apdu.encrypt(encryptionMode: self.environment.encryptionMode, encryptionKey: self.environment.encryptionKey) else {
            completion(.failure(.failedToEstablishEncryption))
            return
        }
        
        self.reader.send(apdu: apduEncrypted) { [unowned self] result in
            switch result {
            case .success(let responseApdu):
                switch responseApdu.statusWord {
                case .processCompleted, .pin1Changed, .pin2Changed, .pin3Changed:
                    guard let decryptedApdu = try? responseApdu.decrypt(encryptionKey: self.environment.encryptionKey) else {
                        completion(.failure(.failedToEstablishEncryption))
                        return
                    }
                    
                    completion(.success(decryptedApdu))
                case .needPause:
                    if let securityDelayResponse = self.deserializeSecurityDelay(with: self.environment, from: responseApdu) {
                        self.viewDelegate.showSecurityDelay(remainingMilliseconds: securityDelayResponse.remainingMilliseconds)
                        if securityDelayResponse.saveToFlash && self.environment.encryptionMode == .none {
                            self.restartPolling()
                        } else {
                            self.sendInternal(apdu: apdu, completion: completion)
                        }
                    }
                default:
                    if let error = responseApdu.statusWord.toSessionError() {
                        self.tryHandleError(error) { handleErrorResult in
                            switch handleErrorResult {
                            case .success:
                                   print("error handled")
                                   if apduEncrypted.ins != Instruction.openSession.rawValue {
                                    self.sendInternal(apdu: apdu, completion: completion)
                                }
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        }
                    } else {
                        completion(.failure(.unknownError))
                    }
                }
            case .failure(let error):
                 completion(.failure(error))
            }
        }
    }
    
    
    /// Perform read slix2 tags
    /// - Parameter completion: Completion handler. Invoked by nfc-reader
    public final func readSlix2Tag(completion: @escaping (Result<ResponseApdu, SessionError>) -> Void)  {
        reader.readSlix2Tag(completion: completion)
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
    private func preflightCheck(_ onSessionStarted: @escaping (CardSession, SessionError?) -> Void) {
        ReadCommand().run(in: self) { [weak self] readResult in
            guard let self = self else { return }
            
            switch readResult {
            case .success(let readResponse):
                if let expectedCardId = self.cardId?.uppercased(),
                    let actualCardId = readResponse.cardId?.uppercased(),
                    expectedCardId != actualCardId {
                    self.viewDelegate.wrongCard(message: SessionError.wrongCard.localizedDescription)                    
                    DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                        self.restartPolling()
                        self.preflightCheck(onSessionStarted)
                    }
                    return
                }
                self.viewDelegate.sessionInitialized()
                onSessionStarted(self, nil)
            case .failure(let error):
                  onSessionStarted(self, error)
                  self.stop(error: error)
            }
        }
    }
    
    private func tryHandleError(_ error: SessionError, completion: @escaping CompletionResult<Void>) {
        switch error {
        case .needEncryption:
            switch self.environment.encryptionMode {
            case .none:
                print("try fast enctiption")
                self.environment.encryptionKey = nil
                self.environment.encryptionMode = .fast
            case .fast:
                 print("try strong enctiption")
                self.environment.encryptionKey = nil
                self.environment.encryptionMode = .strong
            case .strong:
                assertionFailure("Encryption doesn't work")
                completion(.failure(.needEncryption))
            }
            self.establishEncryption(completion: completion)
        default:
            completion(.failure(error))
        }
    }
    
    private func establishEncryption(completion: @escaping CompletionResult<Void>) {
        guard let encryptionHelper = EncryptionHelperFactory.make(for: environment.encryptionMode) else {
            completion(.failure(.failedToEstablishEncryption))
            return
        }
        let openSessionCommand = OpenSessionCommand(sessionKeyA: encryptionHelper.keyA)
        let openSesssionApdu = try! openSessionCommand.serialize(with: environment)
        sendInternal(apdu: openSesssionApdu) { result in
            switch result {
            case .success(let responseApdu):
                let response = try! openSessionCommand.deserialize(with: self.environment, from: responseApdu)
                
                var uid: Data
                if let uidFromResponse = response.uid {
                    uid = uidFromResponse
                } else {
                    if case let .tag(tagUid) = self.connectedTag {
                        uid = tagUid
                    } else {
                        completion(.failure(.failedToEstablishEncryption))
                        return
                    }
                }
                
                guard let protocolKey = self.environment.pin1.pbkdf2sha256(salt: uid, rounds: 50),
                let secret = encryptionHelper.generateSecret(keyB: response.sessionKeyB) else {
                    completion(.failure(.failedToEstablishEncryption))
                    return
                }
                
                let sessionKey = (secret + protocolKey).getSha256()
                self.environment.encryptionKey = sessionKey
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Helper method to parse security delay information received from a card.
    /// - Returns: Remaining security delay in milliseconds.
     private func deserializeSecurityDelay(with environment: SessionEnvironment, from responseApdu: ResponseApdu) -> (remainingMilliseconds: Int, saveToFlash: Bool)? {
        guard let tlv = responseApdu.getTlvData(encryptionKey: environment.encryptionKey),
            let remainingMilliseconds = tlv.value(for: .pause)?.toInt() else {
                return nil
        }
        
        let saveToFlash = tlv.contains(tag: .flash)
        return (remainingMilliseconds, saveToFlash)
    }
}

//ed25519 from cryptokit?
