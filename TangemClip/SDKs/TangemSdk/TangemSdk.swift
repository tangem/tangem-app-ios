//
//  CardManager.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC
import Combine

/// The main interface of Tangem SDK that allows your app to communicate with Tangem cards.
public final class TangemSdk {
    /// Check if the current device doesn't support the desired NFC operations
    public static var isNFCAvailable: Bool {
        if NSClassFromString("NFCNDEFReaderSession") == nil { return false }
        return NFCNDEFReaderSession.readingAvailable
    }
    
    /// Configuration of the SDK. Do not change the default values unless you know what you are doing
    public var config = Config()
    private let reader: CardReader
    private let viewDelegate: SessionViewDelegate
    private let secureStorageService = SecureStorageService()
    private let onlineCardVerifier = OnlineCardVerifier()
    private var cardSession: CardSession? = nil
    private var onlineVerificationCancellable: AnyCancellable? = nil
    private lazy var terminalKeysService: TerminalKeysService = {
        let service = TerminalKeysService(secureStorageService: secureStorageService)
        return service
    }()
    
    /// Default initializer
    /// - Parameters:
    ///   - cardReader: An interface that is responsible for NFC connection and transfer of data to and from the Tangem Card.
    ///   If nil, its default implementation will be used
    ///   - viewDelegate:  An interface that allows interaction with users and shows relevant UI.
    ///   If nil, its default implementation will be used
    ///   - config: Allows to change a number of parameters for communication with Tangem cards.
    ///   Do not change the default values unless you know what you are doing.
    public init(cardReader: CardReader? = nil, viewDelegate: SessionViewDelegate? = nil, config: Config = Config()) {
        let reader = cardReader ?? NFCReader()
        self.reader = reader
        self.viewDelegate = viewDelegate ?? DefaultSessionViewDelegate(reader: reader, config: config)
        self.config = config
    }
    
    /// Get the card info and verify with Tangem backend. Do not use for developer cards
    /// - Parameters:
    ///   - cardPublicKey: CardPublicKey returned by [ReadCommand]
    ///   - cardId: CID, Unique Tangem card ID number.
    ///   - completion: `CardVerifyAndGetInfoResponse.Item`
    public func loadCardInfo(cardPublicKey: Data,
                             cardId: String,
                             completion: @escaping CompletionResult<CardVerifyAndGetInfoResponse.Item>) {
        onlineVerificationCancellable = onlineCardVerifier
            .getCardInfo(cardId: cardId, cardPublicKey: cardPublicKey)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { receivedCompletion in
                if case let .failure(error) = receivedCompletion {
                    completion(.failure(error.toTangemSdkError()))
                }
            }, receiveValue: { response in
                completion(.success(response))
            })
    }
    
    /// Allows running a custom bunch of commands in one NFC Session by creating a custom task. Tangem SDK will start a card session, perform preflight `Read` command,
    /// invoke the `run ` method of `CardSessionRunnable` and close the session.
    /// You can find the current card in the `environment` property of the `CardSession`
    /// - Parameters:
    ///   - runnable: A custom task, adopting `CardSessionRunnable` protocol
    ///   - cardId: CID, Unique Tangem card ID number. If not nil, the SDK will check that you tapped the  card with this cardID and will return the `wrongCard` error' otherwise
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: Standart completion handler. Invoked on the main thread. `(Swift.Result<CardSessionRunnable.CommandResponse, TangemSdkError>) -> Void`.
    public func startSession<T>(with runnable: T,
                                cardId: String? = nil,
                                initialMessage: Message? = nil,
                                completion: @escaping CompletionResult<T.CommandResponse>)
    where T : CardSessionRunnable {
        
        if let existingSession = cardSession, existingSession.state == .active  {
            completion(.failure(.busy))
            return
        }
        configure()
        cardSession = CardSession(environment: buildEnvironment(),
                                  cardId: cardId,
                                  initialMessage: initialMessage,
                                  cardReader: reader,
                                  viewDelegate: viewDelegate)
        
        cardSession!.start(with: runnable, completion: completion)
    }
    
    /// Allows running  a custom bunch of commands in one NFC Session with lightweight closure syntax. Tangem SDK will start a card sesion and perform preflight `Read` command.
    /// - Parameters:
    ///   - cardId: CID, Unique Tangem card ID number. If not nil, the SDK will check that you tapped the  card with this cardID and will return the `wrongCard` error' otherwise
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - callback: At first, you should check that the `TangemSdkError` is not nil, then you can use the `CardSession` to interact with a card.
    ///   You can find the current card in the `environment` property of the `CardSession`
    ///   If you need to interact with UI, you should dispatch to the main thread manually
    public func startSession(cardId: String? = nil,
                             initialMessage: Message? = nil,
                             callback: @escaping (CardSession, TangemSdkError?) -> Void) {
        
        if let existingSession = cardSession, existingSession.state == .active  {
            callback(existingSession, .busy)
            return
        }
        configure()
        cardSession = CardSession(environment: buildEnvironment(),
                                  cardId: cardId,
                                  initialMessage: initialMessage,
                                  cardReader: reader,
                                  viewDelegate: viewDelegate)
        cardSession?.start(callback)
    }
    
    private func configure() {
        viewDelegate.setConfig(config)
        Log.config = config.logСonfig
    }
    
    private func buildEnvironment() -> SessionEnvironment{
        var environment = SessionEnvironment()
        environment.legacyMode = config.legacyMode ?? NfcUtils.isPoorNfcQualityDevice
        if config.linkedTerminal ?? !NfcUtils.isPoorNfcQualityDevice {
            environment.terminalKeys = terminalKeysService.getKeys()
        }
        environment.allowedCardTypes = config.allowedCardTypes
        environment.handleErrors = config.handleErrors
        
        return environment
    }
}
