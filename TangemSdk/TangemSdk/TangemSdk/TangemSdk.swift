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
public final class TangemSdk {
    public static var isNFCAvailable: Bool {
           #if canImport(CoreNFC)
           if NSClassFromString("NFCNDEFReaderSession") == nil { return false }
           return NFCNDEFReaderSession.readingAvailable
           #else
           return false
           #endif
       }
    
    public var config = Config()
 
    private var cardSession: CardSession? = nil
    private let storageService = SecureStorageService()
    
    private lazy var terminalKeysService: TerminalKeysService = {
        let service = TerminalKeysService(secureStorageService: storageService)
        return service
    }()

    public init() {}
    
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
    public func scanCard(completion: @escaping CompletionResult<Card>) {
        cardSession = CardSession(environment: buildEnvironment())
        if #available(iOS 13.0, *) {
            cardSession!.start(with: ScanTask(), completion: completion)
        } else {
            cardSession!.start(with: ScanTaskLegacy(), completion: completion)
        }
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
    public func sign(hashes: [Data], cardId: String, completion: @escaping CompletionResult<SignResponse>) {
        var signCommand: SignCommand
        do {
            signCommand = try SignCommand(hashes: hashes)
            cardSession = CardSession(environment: buildEnvironment(), cardId: cardId)
            cardSession!.start(with: signCommand, completion: completion)
        } catch {
            print(error.localizedDescription)
            completion(.failure(error.toTaskError()))
        }
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
    public func readIssuerData(cardId: String, completion: @escaping CompletionResult<ReadIssuerDataResponse>) {
        cardSession = CardSession(environment: buildEnvironment(), cardId: cardId)
        cardSession!.start(with: ReadIssuerDataCommand(), completion: completion)
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
    public func writeIssuerData(cardId: String, issuerData: Data, issuerDataSignature: Data, issuerDataCounter: Int? = nil, completion: @escaping CompletionResult<WriteIssuerDataResponse>) {
        
        let command = WriteIssuerDataCommand(issuerData: issuerData, issuerDataSignature: issuerDataSignature, issuerDataCounter: issuerDataCounter)
        cardSession = CardSession(environment: buildEnvironment(), cardId: cardId)
        cardSession!.start(with: command, completion: completion)
    }
    
    /**
     * This task retrieves Issuer Extra Data field and its issuer’s signature.
     * Issuer Extra Data is never changed or parsed from within the Tangem COS. The issuer defines purpose of use,
     * format and payload of Issuer Data. . For example, this field may contain photo or
     * biometric information for ID card product. Because of the large size of Issuer_Extra_Data,
     * a series of these commands have to be executed to read the entire Issuer_Extra_Data.
     * @param cardId CID, Unique Tangem card ID number.
     * @param callback is triggered on the completion of the [ReadIssuerExtraDataTask],
     * provides card response in the form of [ReadIssuerExtraDataResponse].
     */
    @available(iOS 13.0, *)
    public func readIssuerExtraData(cardId: String, completion: @escaping CompletionResult<ReadIssuerExtraDataResponse>) {
        let command = ReadIssuerExtraDataCommand(issuerPublicKey: config.issuerPublicKey)
        cardSession = CardSession(environment: buildEnvironment(), cardId: cardId)
        cardSession!.start(with: command, completion: completion)
    }
    
    /**
     * This task writes Issuer Extra Data field and its issuer’s signature.
     * Issuer Extra Data is never changed or parsed from within the Tangem COS.
     * The issuer defines purpose of use, format and payload of Issuer Data.
     * For example, this field may contain a photo or biometric information for ID card products.
     * Because of the large size of Issuer_Extra_Data, a series of these commands have to be executed
     * to write entire Issuer_Extra_Data.
     * @param cardId CID, Unique Tangem card ID number.
     * @param issuerData Data provided by issuer.
     * @param startingSignature Issuer’s signature with Issuer Data Private Key of [cardId],
     * [issuerDataCounter] (if flags Protect_Issuer_Data_Against_Replay and
     * Restrict_Overwrite_Issuer_Extra_Data are set in [SettingsMask]) and size of [issuerData].
     * @param finalizingSignature Issuer’s signature with Issuer Data Private Key of [cardId],
     * [issuerData] and [issuerDataCounter] (the latter one only if flags Protect_Issuer_Data_Against_Replay
     * andRestrict_Overwrite_Issuer_Extra_Data are set in [SettingsMask]).
     * @param issuerDataCounter An optional counter that protect issuer data against replay attack.
     * @param callback is triggered on the completion of the [WriteIssuerDataCommand],
     * provides card response in the form of [WriteIssuerDataResponse].
     */
    @available(iOS 13.0, *)
    public func writeIssuerExtraData(cardId: String,
                                     issuerData: Data,
                                     startingSignature: Data,
                                     finalizingSignature: Data,
                                     issuerDataCounter: Int? = nil,
                                     completion: @escaping CompletionResult<WriteIssuerDataResponse>) {

        let command = WriteIssuerExtraDataCommand(issuerData: issuerData,
                                            issuerPublicKey: config.issuerPublicKey,
                                            startingSignature: startingSignature,
                                            finalizingSignature: finalizingSignature,
                                            issuerDataCounter: issuerDataCounter)
        
        cardSession = CardSession(environment: buildEnvironment(), cardId: cardId)
        cardSession!.start(with: command, completion: completion)
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
    public func createWallet(cardId: String, completion: @escaping CompletionResult<CreateWalletResponse>) {
        cardSession = CardSession(environment: buildEnvironment(), cardId: cardId)
        cardSession!.start(with: CreateWalletTask(), completion: completion)
    }
    
    /**
     * This command deletes all wallet data. If Is_Reusable flag is enabled during personalization,
     * the card changes state to ‘Empty’ and a new wallet can be created by `CREATE_WALLET` command.
     * If Is_Reusable flag is disabled, the card switches to ‘Purged’ state.
     * ‘Purged’ state is final, it makes the card useless.
     * - Parameter cardId: CID, Unique Tangem card ID number.
     */
    @available(iOS 13.0, *)
    public func purgeWallet(cardId: String, completion: @escaping CompletionResult<PurgeWalletResponse>) {
        cardSession = CardSession(environment: buildEnvironment(), cardId: cardId)
        cardSession!.start(with: PurgeWalletCommand(), completion: completion)
    }
    
    public func start<T>(with runnable: T, cardId: String?, completion: @escaping CompletionResult<T.CommandResponse>) where T : CardSessionRunnable {
        cardSession = CardSession(environment: buildEnvironment(), cardId: cardId)
        cardSession!.start(with: runnable, completion: completion)
    }
    
    @available(iOS 13.0, *)
    public func start(cardId: String?, delegate: @escaping (CardSession, SessionError?) -> Void) {
        cardSession = CardSession(environment: buildEnvironment(), cardId: cardId)
        cardSession?.start(delegate: delegate)
    }
    
    private func buildEnvironment() -> CardEnvironment {
        let isLegacyMode = config.legacyMode ?? NfcUtils.isLegacyDevice
        var environment = CardEnvironment()
        environment.legacyMode = isLegacyMode
        if config.linkedTerminal && !isLegacyMode {
            environment.terminalKeys = terminalKeysService.getKeys()
        }
        return environment
    }
}
