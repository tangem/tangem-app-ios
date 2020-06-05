//
//  CardManager.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
#if canImport(CoreNFC)
import CoreNFC
#endif

/// The main interface of Tangem SDK that allows your app to communicate with Tangem cards.
@available(iOS 13.0, *)
public final class TangemSdk {
    /// Check if the current device doesn't support the desired NFC operations
    public static var isNFCAvailable: Bool {
        #if canImport(CoreNFC)
        if NSClassFromString("NFCNDEFReaderSession") == nil { return false }
        return NFCNDEFReaderSession.readingAvailable
        #else
        return false
        #endif
    }
    
    /// Configuration of the SDK. Do not change the default values unless you know what you are doing
    public var config = Config()
    
    private let reader: CardReader
    private let viewDelegate: SessionViewDelegate
    private let storageService = SecureStorageService()
    private var cardSession: CardSession? = nil
    
    private lazy var terminalKeysService: TerminalKeysService = {
        let service = TerminalKeysService(secureStorageService: storageService)
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
        let reader = cardReader ?? CardReaderFactory().createDefaultReader()
        self.reader = reader
        self.viewDelegate = viewDelegate ?? DefaultSessionViewDelegate(reader: reader)
        self.config = config
    }
    
    /**
     * To start using any card, you first need to read it using the `scanCard()` method.
     * This method launches an NFC session, and once it’s connected with the card,
     * it obtains the card data. Optionally, if the card contains a wallet (private and public key pair),
     * it proves that the wallet owns a private key that corresponds to a public one.
     *
     * - Parameters:
     *   - pin1: PIN1 string. Hash will be calculated automatically. If nil, the default PIN1 value will be used
     *   - completion: Returns `Swift.Result<Card,TangemSdkError>`
     */
    public func scanCard(pin1: String? = nil, completion: @escaping CompletionResult<Card>) {
        startSession(with: ScanTask(), cardId: nil, pin1: pin1, completion: completion)
    }
    
    /**
     * This method allows you to sign one or multiple hashes.
     * Simultaneous signing of array of hashes in a single `SignCommand` is required to support
     * Bitcoin-type multi-input blockchains (UTXO).
     * The `SignCommand` will return a corresponding array of signatures.
     * Please note that Tangem cards usually protect the signing with a security delay
     * that may last up to 90 seconds, depending on a card.
     * It is for `SessionViewDelegate` to notify users of security delay.
     *
     * - Parameters:
     *   - hashes: Array of transaction hashes. It can be from one or up to ten hashes of the same length.
     *   - cardId: CID, Unique Tangem card ID number
     *   - pin1: PIN1 string. Hash will be calculated automatically. If nil, the default PIN1 value will be used
     *   - pin2: PIN2 string. Hash will be calculated automatically. If nil, the default PIN2 value will be used
     *   - completion: Returns  `Swift.Result<SignResponse,TangemSdkError>`
     */
    @available(iOS 13.0, *)
    public func sign(hashes: [Data],
                     cardId: String? = nil,
                     pin1: String? = nil,
                     pin2: String? = nil,
                     completion: @escaping CompletionResult<SignResponse>) {
        startSession(with: SignCommand(hashes: hashes),
                     cardId: cardId,
                     pin1: pin1,
                     pin2: pin2,
                     completion: completion)
    }
    
    /**
     * This command returns 512-byte Issuer Data field and its issuer’s signature.
     * Issuer Data is never changed or parsed from within the Tangem COS. The issuer defines purpose of use,
     * format and payload of Issuer Data. For example, this field may contain information about
     * wallet balance signed by the issuer or additional issuer’s attestation data.
     * - Parameters:
     *   - cardId: CID, Unique Tangem card ID number.
     *   - pin1: PIN1 string. Hash will be calculated automatically. If nil, the default PIN1 value will be used
     *   - completion: Returns `Swift.Result<ReadIssuerDataResponse,TangemSdkError>`
     */
    @available(iOS 13.0, *)
    public func readIssuerData(cardId: String? = nil,
                               pin1: String? = nil,
                               completion: @escaping CompletionResult<ReadIssuerDataResponse>) {
        startSession(with: ReadIssuerDataCommand(issuerPublicKey: config.issuerPublicKey),
                     cardId: cardId,
                     pin1: pin1,
                     completion: completion)
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
     *   - pin1: PIN1 string. Hash will be calculated automatically. If nil, the default PIN1 value will be used
     *   - completion: Returns `Swift.Result<WriteIssuerDataResponse,TangemSdkError>`
     */
    @available(iOS 13.0, *)
    public func writeIssuerData(cardId: String? = nil,
                                issuerData: Data,
                                issuerDataSignature: Data,
                                issuerDataCounter: Int? = nil,
                                pin1: String? = nil,
                                completion: @escaping CompletionResult<WriteIssuerDataResponse>) {
        let command = WriteIssuerDataCommand(issuerData: issuerData,
                                             issuerDataSignature: issuerDataSignature,
                                             issuerDataCounter: issuerDataCounter,
                                             issuerPublicKey: config.issuerPublicKey)
        startSession(with: command, cardId: cardId, pin1: pin1, completion: completion)
    }
    
    /**
     * This task retrieves Issuer Extra Data field and its issuer’s signature.
     * Issuer Extra Data is never changed or parsed from within the Tangem COS. The issuer defines purpose of use,
     * format and payload of Issuer Data. . For example, this field may contain photo or
     * biometric information for ID card product. Because of the large size of Issuer_Extra_Data,
     * a series of these commands have to be executed to read the entire Issuer_Extra_Data.
     *
     * - Parameters:
     *   - cardId:  CID, Unique Tangem card ID number.
     *   - pin1: PIN1 string. Hash will be calculated automatically. If nil, the default PIN1 value will be used
     *   - completion: Returns `Swift.Result<ReadIssuerExtraDataResponse,TangemSdkError>`
     */
    @available(iOS 13.0, *)
    public func readIssuerExtraData(cardId: String? = nil,
                                    pin1: String? = nil,
                                    completion: @escaping CompletionResult<ReadIssuerExtraDataResponse>) {
        let command = ReadIssuerExtraDataCommand(issuerPublicKey: config.issuerPublicKey)
        startSession(with: command, cardId: cardId, pin1: pin1, completion: completion)
    }
    
    /**
     * This task writes Issuer Extra Data field and its issuer’s signature.
     * Issuer Extra Data is never changed or parsed from within the Tangem COS.
     * The issuer defines purpose of use, format and payload of Issuer Data.
     * For example, this field may contain a photo or biometric information for ID card products.
     * Because of the large size of Issuer_Extra_Data, a series of these commands have to be executed
     * to write entire Issuer_Extra_Data.
     *
     * - Parameters:
     *   - cardId:  CID, Unique Tangem card ID number.
     *   - issuerData: Data provided by issuer.
     *   - startingSignature: Issuer’s signature with Issuer Data Private Key of [cardId],
     *   [issuerDataCounter] (if flags Protect_Issuer_Data_Against_Replay and
     *   Restrict_Overwrite_Issuer_Extra_Data are set in [SettingsMask]) and size of [issuerData].
     *   - finalizingSignature:  Issuer’s signature with Issuer Data Private Key of [cardId],
     *   [issuerData] and [issuerDataCounter] (the latter one only if flags Protect_Issuer_Data_Against_Replay
     *   and Restrict_Overwrite_Issuer_Extra_Data are set in [SettingsMask]).
     *   - issuerDataCounter:  An optional counter that protect issuer data against replay attack.
     *   - pin1: PIN1 string. Hash will be calculated automatically. If nil, the default PIN1 value will be used
     *   - completion: Returns `Swift.Result<WriteIssuerDataResponse,TangemSdkError>`
     */
    @available(iOS 13.0, *)
    public func writeIssuerExtraData(cardId: String? = nil,
                                     issuerData: Data,
                                     startingSignature: Data,
                                     finalizingSignature: Data,
                                     issuerDataCounter: Int? = nil,
                                     pin1: String? = nil,
                                     completion: @escaping CompletionResult<WriteIssuerDataResponse>) {
        
        let command = WriteIssuerExtraDataCommand(issuerData: issuerData,
                                                  issuerPublicKey: config.issuerPublicKey,
                                                  startingSignature: startingSignature,
                                                  finalizingSignature: finalizingSignature,
                                                  issuerDataCounter: issuerDataCounter)
        
        startSession(with: command, cardId: cardId, pin1: pin1, completion: completion)
    }
    
    /**
     * This method launches a [ReadUserDataCommand]
     *
     * This command returns two up to 512-byte User_Data, User_Protected_Data and two counters User_Counter and
     * User_Protected_Counter fields.
     * User_Data and User_ProtectedData are never changed or parsed by the executable code the Tangem COS.
     * The App defines purpose of use, format and it's payload. For example, this field may contain cashed information
     * from blockchain to accelerate preparing new transaction.
     * User_Counter and User_ProtectedCounter are counters, that initial values can be set by App and increased on every signing
     * of new transaction (on SIGN command that calculate new signatures). The App defines purpose of use.
     * For example, this fields may contain blockchain nonce value.
     *
     * - Parameters:
     *   - cardId:  CID, Unique Tangem card ID number.
     *   - pin1: PIN1 string. Hash will be calculated automatically. If nil, the default PIN1 value will be used
     *   - completion: Returns `Swift.Result<ReadUserDataResponse,TangemSdkError>`
     */
    @available(iOS 13.0, *)
    public func readUserData(cardId: String? = nil,
                             pin1: String? = nil,
                             completion: @escaping CompletionResult<ReadUserDataResponse>) {
        startSession(with: ReadUserDataCommand(), cardId: cardId, pin1: pin1, completion: completion)
    }
    
    /**
     * This method launches a [WriteUserDataCommand]
     *
     * This command writes some UserData, and UserCounter fields.
     * User_Data are never changed or parsed by the executable code the Tangem COS.
     * The App defines purpose of use, format and it's payload. For example, this field may contain cashed information
     * from blockchain to accelerate preparing new transaction.
     * User_Counter are counter, that initial value can be set by App and increased on every signing
     * of new transaction (on SIGN command that calculate new signatures). The App defines purpose of use.
     * For example, this fields may contain blockchain nonce value.
     *
     * Writing of UserCounter and UserData is protected only by PIN1.
     * - Parameters:
     *   - cardId:  CID, Unique Tangem card ID number.
     *   - userData: Data defined by user’s App
     *   - userCounter: Counter initialized by user’s App and increased on every signing of new transaction.  If nil, the current counter value will not be overwritten.
     *   - pin1: PIN1 string. Hash will be calculated automatically. If nil, the default PIN1 value will be used
     *   - completion: Returns `Swift.Result<WriteUserDataResponse,TangemSdkError>`
     */
    @available(iOS 13.0, *)
    public func writeUserData(cardId: String? = nil,
                              userData: Data,
                              userCounter: Int?,
                              pin1: String? = nil,
                              completion: @escaping CompletionResult<WriteUserDataResponse>) {
        let writeUserDataCommand = WriteUserDataCommand(userData: userData, userCounter: userCounter)
        startSession(with: writeUserDataCommand, cardId: cardId, pin1: pin1, completion: completion)
    }
    
    /**
     * This method launches a [WriteUserDataCommand]
     *
     * This command writes some UserProtectedData and UserProtectedCounter fields.
     * User_ProtectedData are never changed or parsed by the executable code the Tangem COS.
     * The App defines purpose of use, format and it's payload. For example, this field may contain cashed information
     * from blockchain to accelerate preparing new transaction.
     * User_ProtectedCounter are counter, that initial value can be set by App and increased on every signing
     * of new transaction (on SIGN command that calculate new signatures). The App defines purpose of use.
     * For example, this fields may contain blockchain nonce value.
     *
     * UserProtectedCounter and UserProtectedData is protected by PIN1 and need additionally PIN2 to confirmation.
     * - Parameters:
     *   - cardId:  CID, Unique Tangem card ID number.
     *   - userProtectedData: Data defined by user’s App (confirmed by PIN2)
     *   - userProtectedCounter: Counter initialized by user’s App (confirmed by PIN2) and increased on every signing of new transaction.  If nil, the current counter value will not be overwritten.
     *   - pin1: PIN1 string. Hash will be calculated automatically. If nil, the default PIN1 value will be used
     *   - completion: Returns `Swift.Result<WriteUserDataResponse,TangemSdkError>`
     */
    @available(iOS 13.0, *)
    public func writeUserProtectedData(cardId: String? = nil,
                                       userProtectedData: Data,
                                       userProtectedCounter: Int?,
                                       pin1: String? = nil,
                                       completion: @escaping CompletionResult<WriteUserDataResponse>) {
        let writeUserDataCommand = WriteUserDataCommand(userProtectedData: userProtectedData, userProtectedCounter: userProtectedCounter)
        startSession(with: writeUserDataCommand, cardId: cardId, pin1: pin1, completion: completion)
    }
    
    /**
     * This command will create a new wallet on the card having ‘Empty’ state.
     * A key pair WalletPublicKey / WalletPrivateKey is generated and securely stored in the card.
     * App will need to obtain Wallet_PublicKey from the response of `CreateWalletCommand` or `ReadCommand`
     * and then transform it into an address of corresponding blockchain wallet
     * according to a specific blockchain algorithm.
     * WalletPrivateKey is never revealed by the card and will be used by `SignCommand` and `CheckWalletCommand`.
     * RemainingSignature is set to MaxSignatures.
     * - Parameters:
     *   - cardId:  CID, Unique Tangem card ID number.
     *   - pin1: PIN1 string. Hash will be calculated automatically. If nil, the default PIN1 value will be used
     *   - pin2: PIN2 string. Hash will be calculated automatically. If nil, the default PIN2 value will be used
     *   - completion: Returns `Swift.Result<CreateWalletResponse,TangemSdkError>`
     */
    @available(iOS 13.0, *)
    public func createWallet(cardId: String? = nil,
                             pin1: String? = nil,
                             pin2: String? = nil,
                             completion: @escaping CompletionResult<CreateWalletResponse>) {
        startSession(with: CreateWalletTask(), cardId: cardId, pin1: pin1, pin2: pin2, completion: completion)
    }
    
    /**
     * This command deletes all wallet data. If Is_Reusable flag is enabled during personalization,
     * the card changes state to ‘Empty’ and a new wallet can be created by `CREATE_WALLET` command.
     * If Is_Reusable flag is disabled, the card switches to ‘Purged’ state.
     * ‘Purged’ state is final, it makes the card useless.
     * - Parameters:
     *   - cardId:  CID, Unique Tangem card ID number.
     *   - pin1: PIN1 string. Hash will be calculated automatically. If nil, the default PIN1 value will be used
     *   - pin2: PIN2 string. Hash will be calculated automatically. If nil, the default PIN2 value will be used
     *   - completion: Returns `Swift.Result<PurgeWalletResponse,TangemSdkError>`
     */
    @available(iOS 13.0, *)
    public func purgeWallet(cardId: String? = nil,
                            pin1: String? = nil,
                            pin2: String? = nil,
                            completion: @escaping CompletionResult<PurgeWalletResponse>) {
        startSession(with: PurgeWalletCommand(), cardId: cardId, pin1: pin1, pin2: pin2, completion: completion)
    }
    
    /// Allows running a custom bunch of commands in one NFC Session by creating a custom task. Tangem SDK will start a card session, perform preflight `Read` command,
    /// invoke the `run ` method of `CardSessionRunnable` and close the session.
    /// You can find the current card in the `environment` property of the `CardSession`
    /// - Parameters:
    ///   - runnable: A custom task, adopting `CardSessionRunnable` protocol
    ///   - cardId: CID, Unique Tangem card ID number. If not nil, the SDK will check that you tapped the  card with this cardID and will return the `wrongCard` error' otherwise
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: Standart completion handler. Invoked on the main thread. `(Swift.Result<CardSessionRunnable.CommandResponse, TangemSdkError>) -> Void`.
    ///   - pin1: PIN1 string. Hash will be calculated automatically. If nil, the default PIN1 value will be used
    ///   - pin2: PIN2 string. Hash will be calculated automatically. If nil, the default PIN2 value will be used
    public func startSession<T>(with runnable: T,
                                cardId: String? = nil,
                                initialMessage: String? = nil,
                                pin1: String? = nil,
                                pin2: String? = nil,
                                completion: @escaping CompletionResult<T.CommandResponse>)
        where T : CardSessionRunnable {
        cardSession = CardSession(environment: buildEnvironment(pin1, pin2),
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
    ///   - pin1: PIN1 string. Hash will be calculated automatically. If nil, the default PIN1 value will be used
    ///   - pin2: PIN2 string. Hash will be calculated automatically. If nil, the default PIN2 value will be used
    @available(iOS 13.0, *)
    public func startSession(cardId: String? = nil,
                             initialMessage: String? = nil,
                             pin1: String? = nil,
                             pin2: String? = nil,
                             callback: @escaping (CardSession, TangemSdkError?) -> Void) {
        cardSession = CardSession(environment: buildEnvironment(pin1, pin2),
                                  cardId: cardId,
                                  initialMessage: initialMessage,
                                  cardReader: reader,
                                  viewDelegate: viewDelegate)
        cardSession?.start(callback)
    }
    
    private func buildEnvironment(_ pin1: String?, _ pin2: String?) -> SessionEnvironment {
        var environment = SessionEnvironment()
        environment.legacyMode = config.legacyMode ?? NfcUtils.isPoorNfcQualityDevice
        if config.linkedTerminal ?? !NfcUtils.isPoorNfcQualityDevice {
            environment.terminalKeys = terminalKeysService.getKeys()
        }
        environment.allowedCardTypes = config.allowedCardTypes
        environment.handleErrors = config.handleErrors
        if let pin1 = pin1 {
            environment.set(pin1: pin1)
        }
        if let pin2 = pin2 {
            environment.set(pin2: pin2)
        }
        return environment
    }
    
    @available(swift, obsoleted: 1.0, renamed: "start")
    public func runTask(_ task: Any, cardId: String? = nil, callback: @escaping (Any) -> Void) {}
}

@available(swift, obsoleted: 1.0, renamed: "TangemSdk")
public final class CardManager {}

@available(swift, obsoleted: 1.0, renamed: "CardSessionRunnable")
public final class Task {}
