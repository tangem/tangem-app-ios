//
//  CardReader.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public enum NFCTagType: Equatable, CustomStringConvertible {
    case tag(uid: Data)
    case unknown

    public var description: String {
        switch self {
        case .tag(let uid):
            return "iso7816 Tag with uid: \(uid)"
        case .unknown:
            return "Unknown NFC Tag type"
        }
    }
}

/// Allows interaction between the phone or any other terminal and Tangem card.
/// Its default implementation, `NfcReader`, is in our module.
public protocol CardReader: class {
	/// For setting alertMessage into NFC popup
    var alertMessage: String { get set }
    var tag: CurrentValueSubject<NFCTagType?,TangemSdkError> { get }
	var isSessionReady: CurrentValueSubject<Bool, Never> { get }
    func startSession(with message: String?)
    func resumeSession()
    func stopSession(with errorMessage: String?)
    func pauseSession(with errorMessage: String?)
    func sendPublisher(apdu: CommandApdu) -> AnyPublisher<ResponseApdu, TangemSdkError>
    func restartPolling()
}

public extension CardReader {
    func startSession(with message: String? = nil) {
        startSession(with: message)
    }
    
    func stopSession(with errorMessage: String? = nil) {
        stopSession(with: errorMessage)
    }
}
