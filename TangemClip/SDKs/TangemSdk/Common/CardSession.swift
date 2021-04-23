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
public protocol CardSessionRunnable {    
    var requiresPin2: Bool { get }
    /// Simple interface for responses received after sending commands to Tangem cards.
    associatedtype CommandResponse: JSONStringConvertible
    
    /// The starting point for custom business logic. Adopt this protocol and use `TangemSdk.startSession` to run
    /// - Parameters:
    ///   - session: You can run commands in this session
    ///   - completion: Call the completion handler to complete the task.
    func run(in session: CardSession, completion: @escaping CompletionResult<CommandResponse>)
}

extension CardSessionRunnable {    
    public var requiresPin2: Bool {
        return false
    }
}

protocol CardSessionPreparable {
    func prepare(_ session: CardSession, completion: @escaping CompletionResult<Void>)
}

/// Allows interaction with Tangem cards. Should be open before sending commands
public class CardSession {
    enum CardSessionState {
        case inactive
        case active
    }
    /// Allows interaction with users and shows visual elements.
    public let viewDelegate: SessionViewDelegate
    
    var state: CardSessionState = .inactive
    /// Contains data relating to the current Tangem card. It is used in constructing all the commands,
    /// and commands can modify `SessionEnvironment`.
    
    private(set) var cardId: String?
    
    public internal(set) var environment: SessionEnvironment
    
    private let reader: CardReader
    private let initialMessage: Message?
    private var sendSubscription: [AnyCancellable] = []
    private var nfcReaderSubscriptions: [AnyCancellable] = []
    
    private var needPreflightRead = true
    private var preflightReadingSettings: PreflightReadSettings = .readCardOnly
    
    private var currentTag: NFCTagType? = nil
    /// Main initializer
    /// - Parameters:
    ///   - environment: Contains data relating to a Tangem card
    ///   - cardId: CID, Unique Tangem card ID number. If not nil, the SDK will check that you tapped the  card with this cardID and will return the `wrongCard` error' otherwise
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - cardReader: NFC-reader implementation
    ///   - viewDelegate: viewDelegate implementation
    public init(environment: SessionEnvironment, cardId: String? = nil, initialMessage: Message? = nil, cardReader: CardReader, viewDelegate: SessionViewDelegate) {
        self.reader = cardReader
        self.viewDelegate = viewDelegate
        self.environment = environment
        self.initialMessage = initialMessage
        self.cardId = cardId
    }
    
    deinit {
        Log.debug("Card session deinit")
    }
    
    // MARK: - Prepearing session
    private func prepareSession<T: CardSessionRunnable>(for runnable: T, completion: @escaping CompletionResult<Void>) {
        Log.session("Prepare card session")
        if let preflightReadCapable = runnable as? PreflightReadCapable {
            needPreflightRead = preflightReadCapable.needPreflightRead
            preflightReadingSettings = preflightReadCapable.preflightReadSettings
        }

        if let preparable = runnable as? CardSessionPreparable {
            preparable.prepare(self, completion: completion)
        } else {
            completion(.success(()))
        }
    }
    
    // MARK: - Session start
    /// This metod starts a card session, performs preflight `Read` command,  invokes the `run ` method of `CardSessionRunnable` and closes the session.
    /// - Parameters:
    ///   - runnable: The CardSessionRunnable implemetation
    ///   - completion: Completion handler. `(Swift.Result<CardSessionRunnable.CommandResponse, TangemSdkError>) -> Void`
    public func start<T>(with runnable: T, completion: @escaping CompletionResult<T.CommandResponse>) where T : CardSessionRunnable {
        guard TangemSdk.isNFCAvailable else {
            completion(.failure(.unsupportedDevice))
            return
        }
        
        guard state == .inactive /*&& !reader.isSessionReady.value */ else {
            completion(.failure(.busy))
            return
        }
        Log.session("Start card session with runnable")
        prepareSession(for: runnable) { prepareResult in
            switch prepareResult {
            case .success:
                self.start() {[weak self] session, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                        return
                    }
                    
                    Log.session("Start runnable")
                    
                    runnable.run(in: self) {[weak self] result in
                        guard let self = self else { return }
                        
                        Log.session("Runnable completed")
                        switch result {
                        case .success(let runnableResponse):
                            self.stop(message: Localization.nfcAlertDefaultDone)
                            DispatchQueue.main.async { completion(.success(runnableResponse)) }
                        case .failure(let error):
                            self.stop(error: error)
                            DispatchQueue.main.async { completion(.failure(error)) }
                        }
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Session subscriptions
    /// Starts a card session and performs preflight `Read` command.
    /// - Parameter onSessionStarted: Delegate with the card session. Can contain error
    public func start(_ onSessionStarted: @escaping (CardSession, TangemSdkError?) -> Void) {
        guard TangemSdk.isNFCAvailable else {
            onSessionStarted(self, .unsupportedDevice)
            return
        }
        
        guard state == .inactive /*&& !reader.isSessionReady.value*/ else {
            onSessionStarted(self, .busy)
            return
        }
        
        Log.session("Start card session with delegate")
        state = .active
        
        reader.tag //Subscription for handle tag lost/connected events and invoke viewDelegate
            .dropFirst()
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .removeDuplicates()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { [unowned self] tag in
                    if tag != nil {
                        self.viewDelegate.tagConnected()
                    } else {
                        self.viewDelegate.tagLost()
                    }
                  })
            .store(in: &nfcReaderSubscriptions)
        
        reader.tag //Subscription for handle tag lost/connected events
            .dropFirst()
            .filter { $0 == nil }
            .sink(receiveCompletion: {_ in},
                  receiveValue: {[unowned self] tag in
                    self.environment.encryptionKey = nil
                  })
            .store(in: &nfcReaderSubscriptions)
        
        reader.isSessionReady //Subscription for handle session events and invoke viewDelegate
            .dropFirst()
            .sink(receiveValue: { [unowned self] isReady in
                isReady ?
                    self.viewDelegate.sessionStarted() :
                    self.viewDelegate.sessionStopped()
            })
            .store(in: &nfcReaderSubscriptions)
        
        reader.tag //Subscription for session initialization and handling any error before session is activated
            .compactMap{ $0 }
            .first()
            .sink(receiveCompletion: { [unowned self] readerCompletion in
                    if case let .failure(error) = readerCompletion {
                        self.stop(error: error)
                        onSessionStarted(self, error)
                    }}, receiveValue: { [unowned self] tag in
                        if case .tag = tag, self.needPreflightRead {
                            self.preflightCheck(onSessionStarted)
                        } else {
                            self.viewDelegate.sessionInitialized()
                            onSessionStarted(self, nil)
                        }
                    })
            .store(in: &nfcReaderSubscriptions)
        
        reader.startSession(with: initialMessage?.alertMessage)
    }
    
    // MARK: - Session stop and pause
    /// Stops the current session with the text message. If nil, the default message will be shown
    /// - Parameter message: The message to show
    public func stop(message: String? = nil) {
        Log.session("Stop session")
        if let message = message {
            viewDelegate.showAlertMessage(message)
        }
        reader.stopSession()
        sessionDidStop()
    }
    
    /// Stops the current session with the error message.  Error's `localizedDescription` will be used
    /// - Parameter error: The error to show
    public func stop(error: Error) {
        Log.session("Stop session")
        reader.stopSession(with: error.localizedDescription)
        sessionDidStop()
    }
    
    func pause(error: TangemSdkError? = nil) {
        reader.pauseSession(with: error?.localizedDescription)
    }
    
    func resume() {
        reader.resumeSession()
    }
    
    // MARK: - Restart polling
    /// Restarts the polling sequence so the reader session can discover new tags.
    public func restartPolling() {
        Log.session("Restart polling")
        reader.restartPolling()
    }
    
    // MARK: - APDU sending
    /// Sends `CommandApdu` to the current card
    /// - Parameters:
    ///   - apdu: The apdu to send
    ///   - completion: Completion handler. Invoked by nfc-reader
    public final func send(apdu: CommandApdu, completion: @escaping CompletionResult<ResponseApdu>) {
        Log.session("Send")
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
            .filter {[unowned self] tag in
                guard let currentTag = currentTag else { return true } //Skip filtration because we have nothing to compare with
                
                if tag != currentTag { //handle wrong tag connection during any operation
                    self.viewDelegate.wrongCard(message: TangemSdkError.wrongCardNumber.localizedDescription)
                    DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                        self.restartPolling()
                    }
                    return false
                } else {
                    return true
                }
            }
            .flatMap { _ in self.establishEncryptionIfNeeded() }
            .flatMap { apdu.encryptPublisher(encryptionMode: self.environment.encryptionMode, encryptionKey: self.environment.encryptionKey) }
            .flatMap { self.reader.sendPublisher(apdu: $0) }
            .flatMap { $0.decryptPublisher(encryptionKey: self.environment.encryptionKey) }
            .sink(receiveCompletion: {[unowned self] readerCompletion in
                self.sendSubscription = []
                if case let .failure(error) = readerCompletion {
                    completion(.failure(error))
                }
            }, receiveValue: {[unowned self] responseApdu in
                self.sendSubscription = []
                completion(.success(responseApdu))
            })
            .store(in: &sendSubscription)
    }
    
    /// We need to remember the tag for the duration of the command to be able to compare this tag with new one on tag from connected/lost events
    func rememberTag() {
        currentTag = reader.tag.value
    }
    
    /// The command has been completed. We don't need this tag anymore
    func releaseTag() {
        currentTag = nil
    }
    
    private func sessionDidStop() {
        nfcReaderSubscriptions = []
        preflightReadingSettings = .readCardOnly
        sendSubscription = []
        viewDelegate.sessionStopped()
        state = .inactive
    }
    
    // MARK: - Preflight check
    private func preflightCheck(_ onSessionStarted: @escaping (CardSession, TangemSdkError?) -> Void) {
        Log.session("Start preflight check")
        PreflightReadTask(readSettings: preflightReadingSettings).run(in: self) { [weak self] readResult in
            guard let self = self else { return }

            switch readResult {
            case .success(let readResponse):
                var wrongCardError: TangemSdkError? = nil
                
                if let expectedCardId = self.cardId?.uppercased(),
                   let actualCardId = readResponse.cardId?.uppercased() {
                    
                    if expectedCardId != actualCardId {
                        wrongCardError = .wrongCardNumber
                    }
                }
                
                if !self.environment.allowedCardTypes.contains(readResponse.cardType) {
                    wrongCardError = .wrongCardType
                }
                
                if let wrongCardError = wrongCardError {
                    self.viewDelegate.wrongCard(message: wrongCardError.localizedDescription)
                    DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                        guard self.reader.isSessionReady.value else {
                            onSessionStarted(self, .userCancelled)
                            self.stop()
                            return
                        }
                        
                        self.restartPolling()
                        self.preflightCheck(onSessionStarted)
                    }
                    return
                }
                
                self.cardId = readResponse.cardId
                self.viewDelegate.sessionInitialized()
                onSessionStarted(self, nil)
            case .failure(let error):
                onSessionStarted(self, error)
                self.stop(error: error)
            }
        }
    }
    
    private func establishEncryptionIfNeeded() -> AnyPublisher<Void, TangemSdkError> {
        if self.environment.encryptionMode == .none || self.environment.encryptionKey != nil {
            return Just(()).setFailureType(to: TangemSdkError.self).eraseToAnyPublisher()
        }
        Log.session("Try establish encryption")
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
                    if let tag = self.reader.tag.value, case let .tag(tagUid) = tag {
                        uid = tagUid
                    } else {
                        return Fail(error: .failedToEstablishEncryption).eraseToAnyPublisher()
                    }
                }
                
                guard let protocolKey = self.environment.pin1.value?.pbkdf2sha256(salt: uid, rounds: 50),
                      let secret = encryptionHelper.generateSecret(keyB: response.sessionKeyB) else {
                    return Fail(error: .cryptoUtilsError).eraseToAnyPublisher()
                }
                
                let sessionKey = (secret + protocolKey).getSha256()
                self.environment.encryptionKey = sessionKey
                return Just(()).setFailureType(to: TangemSdkError.self).eraseToAnyPublisher()
            }.eraseToAnyPublisher()
    }
    
    // MARK: - Request PIN
    func requestPinIfNeeded(_ pinType: PinCode.PinType, _ completion: @escaping CompletionResult<Void>) {
        switch pinType {
        case .pin1:
            guard environment.pin1.value == nil else {
                completion(.success(()))
                return
            }
        case .pin2:
            guard environment.pin2.value == nil else {
                completion(.success(()))
                return
            }
        }
        Log.session("Request pin of type: \(pinType)")
        viewDelegate.requestPin(pinType: pinType, cardId: environment.card?.cardId ?? cardId) {[weak self] pin in
            guard let self = self else { return }
            
            if let pin = pin {
                switch pinType {
                case .pin1:
                    self.environment.pin1 = PinCode(.pin1, stringValue: pin)
                case .pin2:
                    self.environment.pin2 = PinCode(.pin2, stringValue: pin)
                }
                completion(.success(()))
            } else {
                completion(.failure(.userCancelled))
            }
        }
    }
}
