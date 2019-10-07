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
public protocol NFCReaderText: class {
    var alertMessage: String {get set}
}

protocol NFCReaderSessionAdapter {
    func restartPolling()
}

@available(iOS 13.0, *)
public class NFCReader: NSObject {
    static let tagTimeout = 19.0
    static let sessionTimeout = 59.0
    
    public let enableSessionInvalidateByTimer = true
    
    private let connectedTag = CurrentValueSubject<NFCISO7816Tag?,NFCReaderError>(nil)
    private let readerSession = CurrentValueSubject<NFCTagReaderSession?,NFCReaderError>(nil)
    private var subscription: AnyCancellable?
    
    /// Workaround for session timeout error (60 sec)
    private var sessionTimer: Timer?
    
    /// Workaround for tag timeout connection error (20 sec)
    private var tagTimer: Timer?
    
    private func startSessionTimer() {
        guard enableSessionInvalidateByTimer else { return }
        DispatchQueue.global().async {
            self.sessionTimer?.invalidate()
            self.sessionTimer = Timer.scheduledTimer(timeInterval: NFCReader.sessionTimeout, target: self, selector: #selector(self.timerTimeout), userInfo: nil, repeats: false)
        }
    }
    
    private func startTagTimer() {
        guard enableSessionInvalidateByTimer else { return }
        
        DispatchQueue.global().async {
            self.tagTimer?.invalidate()
            self.tagTimer = Timer.scheduledTimer(timeInterval: NFCReader.tagTimeout, target: self, selector: #selector(self.timerTimeout), userInfo: nil, repeats: false)
        }
    }
    
    /// Invalidate session before session will close automatically
    @objc private func timerTimeout() {
        guard let session = readerSession.value,
            session.isReady else { return }
        readerSession.value?.invalidate(errorMessage: Localizations.nfcSessionTimeout)
    }
}

@available(iOS 13.0, *)
extension NFCReader: CardReader {
    /// Start session and try to connect with tag
    public func startSession() {
        if let existingSession = readerSession.value, existingSession.isReady {
            return
        }
        
        let session = NFCTagReaderSession(pollingOption: .iso14443, delegate: self)!
        session.alertMessage = Localizations.nfcAlertDefault
        session.begin()
    }
    
    public func stopSession() {
        guard let session = readerSession.value,
            session.isReady else { return }
        readerSession.value?.invalidate()
    }
    
    /// Send apdu command to connected tag
    /// - Parameter command: serialized apdu
    /// - Parameter completion: result with ResponseApdu or NFCReaderError otherwise
    public func send(commandApdu: CommandApdu, completion: @escaping (CompletionResult<ResponseApdu>) -> Void) {
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
                tag.sendCommand(apdu: NFCISO7816APDU(commandApdu)) {[weak self] (data, sw1, sw2, error) in
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
                        self?.subscription?.cancel()
                    }
                }
            })
    }
}

@available(iOS 13.0, *)
extension NFCReader: NFCTagReaderSessionDelegate {
    public func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        startSessionTimer()
        readerSession.send(session)
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        let nfcError = error as! NFCReaderError
        tagTimer?.invalidate()
        sessionTimer?.invalidate()        
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
        get { return readerSession.value?.alertMessage ?? "" }
        set { readerSession.value?.alertMessage = newValue }
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
