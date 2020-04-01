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
    //Serialize/deserialize apdu errors
    case deserializeApduFailed = 1001
    case encodeFailedTypeMismatch = 1002
    case encodeFailed = 1003
    case decodeFailedMissingTag = 1004
    case decodeFailedTypeMismatch = 1005
    case decodeFailed = 1006
    
    //Card errors
    case unknownStatus = 2001
    case errorProcessingCommand = 2002
    case missingPreflightRead = 2003
    case invalidState = 2004
    case insNotSupported = 2005
    case invalidParams = 2006
    case needEncryption = 2007
    
    //Scan errors
    case verificationFailed = 3000
    case cardError = 3001
    case wrongCard = 3002
    case tooMuchHashesInOneTransaction = 3003
    case emptyHashes = 3004
    case hashSizeMustBeEqual = 3005
    
    case busy = 4000
    case userCancelled = 4001
    case unsupportedDevice = 4002
    
    //NFC error
    case nfcStuck = 5000
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
    
    case missingCounter = 7001
    
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
