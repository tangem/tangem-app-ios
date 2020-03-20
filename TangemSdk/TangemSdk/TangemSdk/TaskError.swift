//
//  TaskError.swift
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
public enum TaskError: Int, Error, LocalizedError {
    //Serialize apdu errors
    case serializeCommandError = 1001
    case encodingError = 1002
    case missingTag = 1003
    case wrongType = 1004
    case convertError = 1005
    
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
    
    public static func parse(_ error: Error) -> TaskError {
        if let readerError = error as? NFCReaderError {
            switch readerError.code {
            case .readerSessionInvalidationErrorUserCanceled:
                return .userCancelled
            case .readerSessionInvalidationErrorSystemIsBusy:
                return .nfcStuck
            default:
                return .nfcReaderError
            }
        } else {
            return (error as? TaskError) ?? TaskError.unknownError
        }
    }
}
