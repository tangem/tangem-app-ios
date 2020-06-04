//
//  TangemSdkError.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC

/**
 * An error class that represent typical errors that may occur when performing Tangem SDK tasks.
 * Errors are propagated back to the caller in callbacks.
 */
public enum TangemSdkError: Int, Error, LocalizedError, Encodable {
    
    //MARK: NFC processing errors
    
    /// This error is returned when  NFC reader loses a tag
    /// (e.g. a user detaches card from the phone's NFC module) while the NFC session is in progress.
    case tagLost = 10001
    
    /// Command was sent to wrong tag type
    case unsupportedCommand = 10003
    
    /// This error is returned when the current device doesn't support the desired NFC operations
    case unsupportedDevice = 10004
    
    /// Start session before
    case sessionInactive = 10005
    
    /// It seems that NFC does not work properly on your iPhone. Try to reboot your iPhone
    case nfcStuck = 10006
    
    case nfcTimeout = 10007
    
    case nfcReaderError = 10008
    
    
    //MARK: Apdu processing errrors
    
    case serializeCommandError = 20001
    
    /// This error is returned when the `ResponseApdu` cannot deserialize bytes to `[Tlv]`
    case deserializeApduFailed = 20002
    
    /// This error is returned when the `TlvEncoder` failed to encode value not matching `TlvTag` value type
    case encodingFailedTypeMismatch = 20003
    
    /// This error is returned when the `TlvEncoder` failed to encode nil value or failed to encode stiring with utf8 encoding
    case encodingFailed = 20004
    
    /// This error is returned when the `TlvDecoder` cannot find desired tag. You can use `decodeOptional` to handle this error automatically
    case decodingFailedMissingTag = 20005
    
    /// This error is returned when the `TlvDecoder` failed to decode value not matching `TlvTag` value type
    case decodingFailedTypeMismatch = 20006
    
    /// This error is returned when the `TlvDecoder` failed to decode value. Please let us know
    case decodingFailed = 20007
    
    case failedToEncryptApdu = 20008
      
    case failedToDecryptApdu = 20009
      
    case failedToEstablishEncryption = 20010
    
    case invalidResponseApdu = 20011
    
    //MARK: Card errrors
    
    /// This error is returned when unknown `StatusWord` is received from a card.
    case unknownStatus = 30001
    
    /// This error is returned when a card's reply is `StatusWord.ErrorProcessingCommand`.
    /// The card sends this status in case of internal card error
    case errorProcessingCommand = 30002
    
    /// This error is returned when a card's reply is `StatusWord.InvalidState`.
    /// The card sends this status when command can not be executed in the current state of a card.
    case invalidState = 30003
    
    /// This error is returned when a card's reply is `StatusWord.InsNotSupported`.
    /// The card sends this status when the card cannot process the `Instruction`.
    case insNotSupported = 30004
    
    /// This error is returned when a card's reply is `StatusWord.InvalidParams`.
    /// The card sends this status when there are wrong or not sufficient parameters in `TLV` request, or wrong `PIN1/PIN2`.
    /// The error may be caused, for example, by wrong parameters of the `ApduSerializable`, encode/decode  errors.
    case invalidParams = 30005
    
    /// This error is returned when a card's reply is `StatusWord.NeedEncryption` and the encryption was not established by TangemSdk.
    case needEncryption = 30006
    
    
    //MARK: Business logic errors
    
    // Personalization Errors
    case alreadyPersonalized = 40101
    
    // Depersonalization Errors
    case cannotBeDepersonalized = 40201
    
    // Read Errors
    case pin1Required = 40401
    
    // CreateWallet Errors
    case alreadyCreated = 40501
    
    // PurgeWallet Errors
    case purgeWalletProhibited = 40601
    
    // SetPin Errors
    case pin1CannotBeChanged = 40801
    case pin2CannotBeChanged = 40802
    case pin1CannotBeDefault = 40803
    
    //Sign Errors
    case noRemainingSignatures = 40901
    
    /// This error is returned when a `SignCommand` receives only empty hashes for signature.
    case emptyHashes = 40902
    
    /// This error is returned when a `SignCommand` receives hashes of different lengths for signature.
    case hashSizeMustBeEqual = 40903
    
    case cardIsEmpty = 40904
    
    case signHashesNotAvailable = 40905
    
    /// Tangem cards can sign currently up to 10 hashes during one `SignCommand`.
    /// This error is returned when a `SignCommand` receives more than 10 hashes to sign.
    case tooMuchHashesInOneTransaction = 40906
    
    // Write Extra Issuer Data Errors
    case extendedDataSizeTooLarge = 41101
    
    // General Errors
    
    case notPersonalized = 40001
    
    case notActivated = 40002
    
    case cardIsPurged = 40003
    
    case pin2OrCvcRequired = 40004
    
    /// This error is returned when SDK checks unsuccessfully either
    /// a card's ability to sign with its private key, or the validity of issuer data.
    case verificationFailed = 40005
    
    /// This error is returned when a [Task] checks unsuccessfully either
    /// a card's ability to sign with its private key, or the validity of issuer data.
    case dataSizeTooLarge = 40006

    /// This error is returned when `ReadIssuerData` or `ReadIssuerExtraData` expects a counter
    /// (when the card's requires it), but the counter is missing.
    case missingCounter = 40007
    
    case overwritingDataIsProhibited = 40008
    
    case dataCannotBeWritten = 40009
    
    /// This error is returned when `issuerPublicKey` requires to perform operation
    case missingIssuerPublicKey = 40010
    
    
    //MARK: SDK errors
    
    case unknownError = 50001
    
    /// This error is returned when a user manually closes the NFC  Dialog.
    case userCancelled = 50002
    
    /// This error is returned when `CardSession`  was called with a new operation,  while a previous operation is still in progress.
    case busy = 50003
    
    /// This error is returned when a `CardSessionRunnable` requires that `ReadCommand`
    /// is executed before performing other commands.
    case missingPreflightRead = 50004

    /// This error is returned when a [Task] expects a user to use a particular card,
    /// but the user tries to use a different card.
    case wrongCardNumber = 50005
    
    /// This error is returned when a user scans a card of a [com.tangem.common.extensions.CardType]
    /// that is not specified in [Config.cardFilter].
    case wrongCardType = 50006
    
    /// This error is returned when the scanned card doesn't have some essential fields.
    case cardError = 50007
    
    /// This error is returned when SDK fails to perform some low-level crypto algorithm
    case cryptoUtilsError = 50008
    
    /// This error is returned when the error occurs inside third-party crypto libraries code
    case failedToGenerateRandomSequence = 50009

    
    //MARK: Underlying NFC reader errors
    case readerErrorUnsupportedFeature = 90003
    case readerErrorSecurityViolation = 90004
    case readerErrorInvalidParameter = 90005
    case readerErrorInvalidParameterLength = 90006
    case readerErrorParameterOutOfBound = 90007
    case readerTransceiveErrorTagConnectionLost = 90008
    case readerTransceiveErrorRetryExceeded = 90009
    case readerTransceiveErrorTagResponseError = 90010
    case readerTransceiveErrorSessionInvalidated = 90011
    case readerTransceiveErrorTagNotConnected = 90012
    case readerSessionInvalidationErrorSessionTimeout = 90013
    case readerSessionInvalidationErrorSessionTerminatedUnexpectedly = 90014
    case readerSessionInvalidationErrorFirstNDEFTagRead = 90015
    case tagCommandConfigurationErrorInvalidParameters = 90016
    case ndefReaderSessionErrorTagNotWritable = 90017
    case ndefReaderSessionErrorTagUpdateFailure = 90018
    case ndefReaderSessionErrorTagSizeTooSmall = 90019
    case ndefReaderSessionErrorZeroLengthMessage = 90020
    
    public var code: Int {
        return rawValue
    }
    
    public var errorDescription: String? {
        switch self {
        case .nfcTimeout:
            return Localization.nfcSessionTimeout
        case .nfcStuck:
            return Localization.nfcStuckError
        default:
            let description = "\(self)".capitalizingFirst()
            return Localization.genericErrorCode("\(self.rawValue). \(description)")
        }
    }
    
    public var jsonDescription: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        let data = (try? encoder.encode(self)) ?? Data()
        return String(data: data, encoding: .utf8)!
    }
    
    public var isUserCancelled: Bool {
        if case .userCancelled = self {
            return true
        } else {
            return false
        }
    }
    
    public static func parse(_ error: Error) -> TangemSdkError {
        if let readerError = error as? NFCReaderError {
            switch readerError.code {
            case .readerSessionInvalidationErrorUserCanceled:
                return .userCancelled
            case .readerSessionInvalidationErrorSystemIsBusy:
                return .nfcStuck
            case .readerErrorUnsupportedFeature:
                return .readerErrorUnsupportedFeature
            case .readerErrorSecurityViolation:
                return .readerErrorSecurityViolation
            case .readerErrorInvalidParameter:
                return .readerErrorInvalidParameter
            case .readerErrorInvalidParameterLength:
                return .readerErrorInvalidParameterLength
            case .readerErrorParameterOutOfBound:
                return readerErrorParameterOutOfBound
            case .readerTransceiveErrorTagConnectionLost:
                return .readerTransceiveErrorTagConnectionLost
            case .readerTransceiveErrorRetryExceeded:
                return .readerTransceiveErrorRetryExceeded
            case .readerTransceiveErrorTagResponseError:
                return .readerTransceiveErrorTagResponseError
            case .readerTransceiveErrorSessionInvalidated:
                return .readerTransceiveErrorSessionInvalidated
            case .readerTransceiveErrorTagNotConnected:
                return .readerTransceiveErrorTagNotConnected
            case .readerSessionInvalidationErrorSessionTimeout:
                return readerSessionInvalidationErrorSessionTimeout
            case .readerSessionInvalidationErrorSessionTerminatedUnexpectedly:
                return .readerSessionInvalidationErrorSessionTerminatedUnexpectedly
            case .readerSessionInvalidationErrorFirstNDEFTagRead:
                return .readerSessionInvalidationErrorFirstNDEFTagRead
            case .tagCommandConfigurationErrorInvalidParameters:
                return .tagCommandConfigurationErrorInvalidParameters
            case .ndefReaderSessionErrorTagNotWritable:
                return .ndefReaderSessionErrorTagNotWritable
            case .ndefReaderSessionErrorTagUpdateFailure:
                return .ndefReaderSessionErrorTagUpdateFailure
            case .ndefReaderSessionErrorTagSizeTooSmall:
                return .ndefReaderSessionErrorTagSizeTooSmall
            case .ndefReaderSessionErrorZeroLengthMessage:
                return .ndefReaderSessionErrorZeroLengthMessage
            @unknown default:
                return .nfcReaderError
            }
        } else {
            return (error as? TangemSdkError) ?? TangemSdkError.unknownError
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var error = [String:String]()
        error["code"] = String(describing: code)
        error["localizedDescription"] = localizedDescription
        var container = encoder.singleValueContainer()
        try container.encode(error)
    }
}
