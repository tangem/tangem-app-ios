//
//  CardManager.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC
/// The main interface of Tangem SDK that allows your app to communicate with Tangem cards.
public final class CardManager {
    public static var isNFCAvailable: Bool {
        #if canImport(CoreNFC)
        if NSClassFromString("NFCNDEFReaderSession") == nil { return false }
        return NFCNDEFReaderSession.readingAvailable
        #else
        return false
        #endif
    }
    
    public var isBusy: Bool = false
    
    /// `cardReader` is an interface that is responsible for NFC connection and  transfer of data to and from the Tangem Card.
    private let cardReader: CardReader
    
    /// An interface that allows interaction with users and shows relevant UI.
    private let cardManagerDelegate: CardManagerDelegate
    private var cardEnvironmentRepository: [String:CardEnvironment] = [:]
    private var currentTask: AnyTask?
    
    public init(cardReader: CardReader, cardManagerDelegate: CardManagerDelegate) {
        self.cardReader = cardReader
        self.cardManagerDelegate = cardManagerDelegate
    }
    
    /**
     * To start using any card, you first need to read it using the `scanCard()` method.
     * This method launches an NFC session, and once it’s connected with the card,
     * it obtains the card data. Optionally, if the card contains a wallet (private and public key pair),
     * it proves that the wallet owns a private key that corresponds to a public one.
     *
     * - Parameter callback:This method  will send the following events in a callback:
     * `onRead(Card)` after completing `ReadCommand`
     * `onVerify(Bool)` after completing `CheckWalletCommand`
     * `completion(TaskError?)` with an error field null after successful completion of a task or
     *  with an error if some error occurs.
     */
    public func scanCard(callback: @escaping (TaskEvent<ScanEvent>) -> Void) {
        let task = ScanTask()
        runTask(task, callback: callback)
    }
    
    /**
     * This method allows you to sign one or multiple hashes.
     * Simultaneous signing of array of hashes in a single `SignCommand` is required to support
     * Bitcoin-type multi-input blockchains (UTXO).
     * The `SignCommand` will return a corresponding array of signatures.
     *
     * - Parameter callback: This method  will send the following events in a callback:
     * `SignResponse` after completing `SignCommand`
     * `completion(TaskError?)` with an error field null after successful completion of a task or with an error if some error occurs.
     * Please note that Tangem cards usually protect the signing with a security delay
     * that may last up to 90 seconds, depending on a card.
     * It is for `CardManagerDelegate` to notify users of security delay.
     * - Parameter hashes: Array of transaction hashes. It can be from one or up to ten hashes of the same length.
     * - Parameter cardId: CID, Unique Tangem card ID number
     */
    @available(iOS 13.0, *)
    public func sign(hashes: [Data], cardId: String, callback: @escaping (TaskEvent<SignResponse>) -> Void) {
        var signCommand: SignCommand
        do {
            signCommand = try SignCommand(hashes: hashes, cardId: cardId)
        } catch {
            if let taskError = error as? TaskError {
                callback(.completion(taskError))
            } else {
                callback(.completion(TaskError.genericError(error)))
            }
            return
        }
        
        let task = SingleCommandTask(signCommand)
        runTask(task, cardId: cardId, callback: callback)
    }
    
   /// Allows to run a custom task created outside of this SDK.
    public func runTask<T>(_ task: Task<T>, cardId: String? = nil, callback: @escaping (TaskEvent<T>) -> Void) {
        guard CardManager.isNFCAvailable else {
            callback(.completion(TaskError.unsupported))
            return
        }
        
        guard !isBusy else {
            callback(.completion(TaskError.busy))
            return
        }
        
        currentTask = task
        isBusy = true
        task.reader = cardReader
        task.delegate = cardManagerDelegate
        let environment = fetchCardEnvironment(for: cardId)
        
        task.run(with: environment) {[weak self] taskResult in
            switch taskResult {
            case .event(let event):
                DispatchQueue.main.async {
                    callback(.event(event))
                }
            case .completion(let error):
                DispatchQueue.main.async {
                    callback(.completion(error))
                }
                self?.isBusy = false
                self?.currentTask = nil
            }
        }
    }
    
   /// Allows to run a custom command created outside of this SDK.
    @available(iOS 13.0, *)
    public func runCommand<T: CommandSerializer>(_ command: T, cardId: String? = nil, callback: @escaping (TaskEvent<T.CommandResponse>) -> Void) {
        let task = SingleCommandTask<T>(command)
        runTask(task, cardId: cardId, callback: callback)
    }
    
    private func fetchCardEnvironment(for cardId: String?) -> CardEnvironment {
        guard let cardId = cardId else {
            return CardEnvironment()
        }
        
        return cardEnvironmentRepository[cardId] ?? CardEnvironment()
    }
}

extension CardManager {
    public convenience init(cardReader: CardReader? = nil, cardManagerDelegate: CardManagerDelegate? = nil) {
        let reader = cardReader ?? CardReaderFactory().createDefaultReader()
        let delegate = cardManagerDelegate ?? DefaultCardManagerDelegate(reader: reader)
        self.init(cardReader: reader, cardManagerDelegate: delegate)
    }
}
