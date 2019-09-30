//
//  NFCReader.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Combine
#if canImport(CoreNFC)
import CoreNFC
#endif

@available(iOS 13.0, *)
typealias IOSNFCReader = CardReader & NFCReaderText & NFCReaderSessionAdapter

/// For setting alertMessage into NFC popup
public protocol NFCReaderText {
    var alertMessage: String {get set}
}

protocol NFCReaderSessionAdapter {
    func restartPolling()
}

@available(iOS 13.0, *)
public class NFCReader: NSObject {
    private let connectedTag = CurrentValueSubject<NFCISO7816Tag?,NFCReaderError>(nil)
    private let readerSession = CurrentValueSubject<NFCTagReaderSession?,NFCReaderError>(nil)
    private var subscription: AnyCancellable?
    private var _alertMessage: String?
    
    /// Workaround for session timeout error (60 sec)
    private var sessionTimer: Timer?
    
    /// Workaround for tag timeout connection error (20 sec)
    private var tagTimer: Timer?
    
    private func startSessionTimer() {
        DispatchQueue.global().async {
            self.sessionTimer?.invalidate()
            self.sessionTimer = Timer.scheduledTimer(timeInterval: Constants.sessionTimeout, target: self, selector: #selector(self.timerTimeout), userInfo: nil, repeats: false)
        }
    }
    
    private func startTagTimer() {
        DispatchQueue.global().async {
            self.tagTimer?.invalidate()
            self.tagTimer = Timer.scheduledTimer(timeInterval: Constants.tagTimeout, target: self, selector: #selector(self.timerTimeout), userInfo: nil, repeats: false)
        }
    }
    
    /// Invalidate session before session will close automatically
    @objc private func timerTimeout() {
        stopSession()
    }
}

@available(iOS 13.0, *)
extension NFCReader: CardReader {
    /// Start session and try to connect with tag
    public func startSession() {
        let session = NFCTagReaderSession(pollingOption: .iso14443, delegate: self)!
        if let alertMessage = _alertMessage {
            session.alertMessage = alertMessage
        }
        startSessionTimer()
        session.begin()
        readerSession.send(session)
    }
    
    public func stopSession() {
        guard let session = readerSession.value,
            session.isReady else { return }
        
        readerSession.value?.invalidate()
    }
    
    /// Send apdu command to connected tag
    /// - Parameter command: serialized apdu
    /// - Parameter completion: result with ResponseApdu or NFCReaderError otherwise
    public func send(command: NFCISO7816APDU, completion: @escaping (TangemResult<ResponseApdu>) -> Void) {
        subscription = Publishers.CombineLatest(readerSession, connectedTag) //because of readerSession and connectedTag bouth can produce errors
            .compactMap({ (session, tag) -> (NFCTagReaderSession, NFCISO7816Tag)? in  //ignore initial nil values
                guard let s = session, let t = tag else {
                    return nil
                }
                return (s,t)
            })
            .sink(receiveCompletion: { subscriptionCompletion in
                switch subscriptionCompletion {
                case .failure(let error):  //handle all errors here
                    completion(.failure(error))
                default: //ignore success completion
                    break
                }
            }, receiveValue: { value in
                let tag = value.1  // get connected tag
                tag.sendCommand(apdu: command) {[weak self] (data, sw1, sw2, error) in
                    if let nfcError = error as? NFCReaderError {
                        if nfcError.code == .readerTransceiveErrorTagConnectionLost {
                            DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                                self?.readerSession.value?.restartPolling()  //try restart polling
                            }
                        } else {
                            self?.connectedTag.send(completion: Subscribers.Completion<NFCReaderError>.failure(nfcError)) // Complere subscription and invoke error handler
                        }
                    } else {
                        let responseApdu = ResponseApdu(data, sw1 ,sw2)
                        completion(.success(responseApdu))
                        self?.connectedTag.send(completion: Subscribers.Completion<NFCReaderError>.finished)
                    }
                }
            })
    }
}

@available(iOS 13.0, *)
extension NFCReader: NFCTagReaderSessionDelegate {
    public func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        let nfcError = error as! NFCReaderError
        readerSession.send(completion: Subscribers.Completion<NFCReaderError>.failure(nfcError))
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        let nfcTag = tags.first!
        if case let .iso7816(tag7816) = nfcTag {
            session.connect(to: nfcTag) {[weak self] error in
                if let nfcError = error as? NFCReaderError {
                    session.invalidate(errorMessage: nfcError.localizedDescription)
                    return
                }
                self?.startTagTimer()
                self?.connectedTag.send(tag7816)
            }
        }
    }
}

@available(iOS 13.0, *)
extension NFCReader: NFCReaderText {
    public var alertMessage: String {
        get { return _alertMessage ?? "" }
        set {
            _alertMessage = newValue
            readerSession.value?.alertMessage = newValue
        }
    }
}

@available(iOS 13.0, *)
extension NFCReader: NFCReaderSessionAdapter {
    func restartPolling() {
        guard let session = readerSession.value,
            session.isReady else { return }
        
        DispatchQueue.global().async {
            self.tagTimer?.invalidate()
        }
        
        session.restartPolling()
    }
}

//MARK: Constants
@available(iOS 13.0, *)
private extension NFCReader {
    private enum Constants {
        static let tagTimeout = 19.0
        static let sessionTimeout = 59.0
    }
}
