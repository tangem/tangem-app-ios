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
    
    public var config = Config()
    
    /// `cardReader` is an interface that is responsible for NFC connection and  transfer of data to and from the Tangem Card.
    private let cardReader: CardReader
    
    /// An interface that allows interaction with users and shows relevant UI.
    private let cardManagerDelegate: CardManagerDelegate
    private var isBusy: Bool = false
    private var currentTask: AnyTask?
    private let storageService = SecureStorageService()
    
    private lazy var terminalKeysService: TerminalKeysService = {
        let service = TerminalKeysService(secureStorageService: storageService)
        return service
    }()
    
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
            signCommand = try SignCommand(hashes: hashes)
        } catch {
            print(error.localizedDescription)
            callback(.completion(TaskError.parse(error)))
            return
        }
        
        let task = SingleCommandTask(signCommand)
        runTask(task, cardId: cardId, callback: callback)
    }
        
    /**
     * This command returns 512-byte Issuer Data field and its issuer’s signature.
     * Issuer Data is never changed or parsed from within the Tangem COS. The issuer defines purpose of use,
     * format and payload of Issuer Data. For example, this field may contain information about
     * wallet balance signed by the issuer or additional issuer’s attestation data.
     * - Parameters:
     *   - cardId: CID, Unique Tangem card ID number.
     *   - callback: is triggered on the completion of the `ReadIssuerDataCommand`,
     * provides card response in the form of `ReadIssuerDataResponse`.
     */
    @available(iOS 13.0, *)
    public func readIssuerData(cardId: String, callback: @escaping (TaskEvent<ReadIssuerDataResponse>) -> Void) {
        let command = ReadIssuerDataCommand()
        let task = SingleCommandTask(command)
        runTask(task, cardId: cardId, callback: callback)
    }
    
    /**
     * This command writes 512-byte Issuer Data field and its issuer’s signature.
     * Issuer Data is never changed or parsed from within the Tangem COS. The issuer defines purpose of use,
     * format and payload of Issuer Data. For example, this field may contain information about
     * wallet balance signed by the issuer or additional issuer’s attestation data.
     * - Parameters:
     *   - cardId:  CID, Unique Tangem card ID number.
     *   - issuerData: Data provided by issuer.
     *   - issuerDataSignature: Issuer’s signature of `issuerData` with Issuer Data Private Key (which is kept on card).
     *   - issuerDataCounter: An optional counter that protect issuer data against replay attack.
     *   - callback: is triggered on the completion of the `WriteIssuerDataCommand`,
     * provides card response in the form of  `WriteIssuerDataResponse`.
     */
    @available(iOS 13.0, *)
    public func writeIssuerData(cardId: String, issuerData: Data, issuerDataSignature: Data, issuerDataCounter: Int? = nil, callback: @escaping (TaskEvent<WriteIssuerDataResponse>) -> Void) {
        let command = WriteIssuerDataCommand(issuerData: issuerData, issuerDataSignature: issuerDataSignature, issuerDataCounter: issuerDataCounter)
        let task = SingleCommandTask(command)
        runTask(task, cardId: cardId, callback: callback)
    }
    
    /**
     * This command will create a new wallet on the card having ‘Empty’ state.
     * A key pair WalletPublicKey / WalletPrivateKey is generated and securely stored in the card.
     * App will need to obtain Wallet_PublicKey from the response of `CreateWalletCommand` or `ReadCommand`
     * and then transform it into an address of corresponding blockchain wallet
     * according to a specific blockchain algorithm.
     * WalletPrivateKey is never revealed by the card and will be used by `SignCommand` and `CheckWalletCommand`.
     * RemainingSignature is set to MaxSignatures.
     * - Parameter cardId: CID, Unique Tangem card ID number.
     */
    @available(iOS 13.0, *)
    public func createWallet(cardId: String, callback: @escaping (TaskEvent<CreateWalletEvent>) -> Void) {
        let task = CreateWalletTask(verifyWallet: true)
        runTask(task, cardId: cardId, callback: callback)
    }
    
    /**
     * This command deletes all wallet data. If Is_Reusable flag is enabled during personalization,
     * the card changes state to ‘Empty’ and a new wallet can be created by `CREATE_WALLET` command.
     * If Is_Reusable flag is disabled, the card switches to ‘Purged’ state.
     * ‘Purged’ state is final, it makes the card useless.
     * - Parameter cardId: CID, Unique Tangem card ID number.
     */
    @available(iOS 13.0, *)
    public func purgeWallet(cardId: String, callback: @escaping (TaskEvent<PurgeWalletResponse>) -> Void) {
        let command = PurgeWalletCommand()
        let task = SingleCommandTask(command)
        runTask(task, cardId: cardId, callback: callback)
    }

   /// Allows to run a custom task created outside of this SDK.
    public func runTask<T>(_ task: Task<T>, cardId: String? = nil, callback: @escaping (TaskEvent<T>) -> Void) {
        guard CardManager.isNFCAvailable else {
            callback(.completion(TaskError.unsupportedDevice))
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
        let environment = prepareCardEnvironment(for: cardId)
        
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
    
    private func prepareCardEnvironment(for cardId: String?) -> CardEnvironment {
        let isLegacyMode = config.legacyMode ?? NfcUtils.isLegacyDevice
        var environment = CardEnvironment()
        environment.cardId = cardId
        environment.legacyMode = isLegacyMode
        if config.linkedTerminal && !isLegacyMode {
            environment.terminalKeys = terminalKeysService.getKeys()
        }        
        return environment
    }
}

extension CardManager {
    public convenience init(cardReader: CardReader? = nil, cardManagerDelegate: CardManagerDelegate? = nil) {
        let reader = cardReader ?? CardReaderFactory().createDefaultReader()
        let delegate = cardManagerDelegate ?? DefaultCardManagerDelegate(reader: reader)
        self.init(cardReader: reader, cardManagerDelegate: delegate)
    }
}
