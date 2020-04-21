//
//  SessionError.swift
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
public enum SessionError: Int, Error, LocalizedError {
    /// This error is returned when the `ResponseApdu` cannot deserialize bytes to `[Tlv]`
    case deserializeApduFailed = 1001
    
    /// This error is returned when the `TlvEncoder` failed to encode value not matching `TlvTag` value type
    case encodeFailedTypeMismatch = 1002
    
    ///This error is returned when the `TlvEncoder` failed to encode nil value or failed to encode stiring with utf8 encoding
    case encodeFailed = 1003
    
    /// This error is returned when the `TlvDecoder` cannot find desired tag. You can use `decodeOptional` to handle this error automatically
    case decodeFailedMissingTag = 1004
    
    /// This error is returned when the `TlvDecoder` failed to decode value not matching `TlvTag` value type
    case decodeFailedTypeMismatch = 1005
    
    /// This error is returned when the `TlvDecoder` failed to decode value. Please let us know
    case decodeFailed = 1006
    
    /// This error is returned when unknown `StatusWord` is received from a card.
    case unknownStatus = 2001
    
    /// This error is returned when a card's reply is `StatusWord.ErrorProcessingCommand`.
    /// The card sends this status in case of internal card error
    case errorProcessingCommand = 2002
    
    /// This error is returned when a `CardSessionRunnable` requires that `ReadCommand`
    /// is executed before performing other commands.
    case missingPreflightRead = 2003
    
    /// This error is returned when a card's reply is `StatusWord.InvalidState`.
    /// The card sends this status when command can not be executed in the current state of a card.
    case invalidState = 2004
    
    /// This error is returned when a card's reply is `StatusWord.InsNotSupported`.
    /// The card sends this status when the card cannot process the `Instruction`.
    case insNotSupported = 2005
    
    /// This error is returned when a card's reply is `StatusWord.InvalidParams`.
    /// The card sends this status when there are wrong or not sufficient parameters in `TLV` request, or wrong `PIN1/PIN2`.
    /// The error may be caused, for example, by wrong parameters of the `ApduSerializable`, encode/decode  errors.
    case invalidParams = 2006
    
    /// This error is returned when a card's reply is `StatusWord.NeedEncryption` and the encryption was not established by TangemSdk.
    case needEncryption = 2007
    
    /// This error is returned when SDK checks unsuccessfully either
    /// a card's ability to sign with its private key, or the validity of issuer data.
    case verificationFailed = 3000
    
    /// This error is returned when the scanned card doesn't have some essential fields.
    case cardError = 3001
    
    /// This error is returned when SDK expects a user to use a particular card, and a user tries to use a different card.
    case wrongCard = 3002
    
    /// Tangem cards can sign currently up to 10 hashes during one `SignCommand`.
    /// This error is returned when a `SignCommand` receives more than 10 hashes to sign.
    case tooMuchHashesInOneTransaction = 3003
    
    /// This error is returned when a `SignCommand` receives only empty hashes for signature.
    case emptyHashes = 3004
    
    /// This error is returned when a `SignCommand` receives hashes of different lengths for signature.
    case hashSizeMustBeEqual = 3005
    
    /// This error is returned when the error occurs inside third-party crypto libraries code
    case failedToGenerateRandomSequence = 3007
    
    /// This error is returned when SDK fails to perform some low-level crypto algorithm
    case cryptoUtilsError = 3008
    
    /// This error is returned when `CardSession`  was called with a new operation,  while a previous operation is still in progress.
    case busy = 4000
    
    /// This error is returned when a user manually closes the NFC  Dialog.
    case userCancelled = 4001
    
    /// This error is returned when the current device doesn't support the desired NFC operations
    case unsupportedDevice = 4002
    
    /// It seems that NFC does not work properly on your iPhone. Try to reboot your iPhone
    case nfcStuck = 5000
    
    // Underlying NFC reader errors
    case nfcTimeout = 5001
    case nfcReaderError = 5002
    case readerErrorUnsupportedFeature = 5003
    case readerErrorSecurityViolation = 5004
    case readerErrorInvalidParameter = 5005
    case readerErrorInvalidParameterLength = 5006
    case readerErrorParameterOutOfBound = 5007
    case readerTransceiveErrorTagConnectionLost = 5008
    case readerTransceiveErrorRetryExceeded = 5009
    case readerTransceiveErrorTagResponseError = 5010
    case readerTransceiveErrorSessionInvalidated = 5011
    case readerTransceiveErrorTagNotConnected = 5012
    case readerSessionInvalidationErrorSessionTimeout = 5013
    case readerSessionInvalidationErrorSessionTerminatedUnexpectedly = 5014
    case readerSessionInvalidationErrorFirstNDEFTagRead = 5015
    case tagCommandConfigurationErrorInvalidParameters = 5016
    case ndefReaderSessionErrorTagNotWritable = 5017
    case ndefReaderSessionErrorTagUpdateFailure = 5018
    case ndefReaderSessionErrorTagSizeTooSmall = 5019
    case ndefReaderSessionErrorZeroLengthMessage = 5020
    
    case unknownError = 6000
    
    /// This error is returned when `issuerDataCounter` requires to perform operation
    case missingCounter = 7001
    
    /// This error is returned when `issuerPublicKey ` requires to perform operation
    case missingIssuerPublicKey = 7002
    
    public var errorDescription: String? {
        switch self {
        case .nfcTimeout:
            return Localization.nfcSessionTimeout
        case .nfcStuck:
            return Localization.nfcStuckError
        default:
            return Localization.genericErrorCode("\(self.rawValue)")
        }
    }
    
    public var isUserCancelled: Bool {
        if case .userCancelled = self {
            return true
        } else {
            return false
        }
    }
    
    public static func parse(_ error: Error) -> SessionError {
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
            return (error as? SessionError) ?? SessionError.unknownError
        }
    }
}
