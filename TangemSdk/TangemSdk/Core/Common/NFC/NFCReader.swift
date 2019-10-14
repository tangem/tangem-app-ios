//
//  NFCReader.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CoreNFC

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
enum NFCTagWrapper {
    case tag(NFCISO7816Tag)
    case error(NFCReaderError)
}

@available(iOS 13.0, *)
public final class NFCReader: NSObject {
    static let tagTimeout = 19.0
    static let sessionTimeout = 59.0
    
    public let enableSessionInvalidateByTimer = true
    
    private let connectedTag = CurrentValueSubject<NFCTagWrapper?,Never>(nil)
    private let readerSessionError = CurrentValueSubject<NFCReaderError?,Never>(nil)
    private var readerSession: NFCTagReaderSession?
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
        guard let session = readerSession,
            session.isReady else { return }
        
        session.invalidate(errorMessage: Localizations.nfcSessionTimeout)
    }
}

@available(iOS 13.0, *)
extension NFCReader: CardReader {
    /// Start session and try to connect with tag
    public func startSession() {
        if let existingSession = readerSession, existingSession.isReady { return }
        
        readerSession = NFCTagReaderSession(pollingOption: .iso14443, delegate: self)!
        readerSession!.alertMessage = Localizations.nfcAlertDefault
        readerSession!.begin()
    }
    
    public func stopSession() {
        guard let session = readerSession, session.isReady else { return }
        
        session.invalidate()
    }
    
    /// Send apdu command to connected tag
    /// - Parameter command: serialized apdu
    /// - Parameter completion: result with ResponseApdu or NFCReaderError otherwise
    public func send(commandApdu: CommandApdu, completion: @escaping (CompletionResult<ResponseApdu, NFCReaderError>) -> Void) {
        subscription = Publishers.CombineLatest(readerSessionError, connectedTag) //because of readerSession and connectedTag bouth can produce errors
            .sink(receiveValue: {[weak self] value in
                guard let self = self else { return }
                
                if case let .error(tagError) = value.1  {
                    completion(.failure(tagError))
                    self.subscription?.cancel()
                    return
                }
                
                if let sessionError = value.0  {
                    completion(.failure(sessionError))
                    self.subscription?.cancel()
                    return
                }
                
                guard case let .tag(tag) = value.1 else { //skip initial tag value
                    return
                }
                
                tag.sendCommand(apdu: NFCISO7816APDU(commandApdu)) {[weak self] (data, sw1, sw2, error) in
                    if let nfcError = error as? NFCReaderError {
                        if nfcError.code == .readerTransceiveErrorTagConnectionLost {
                            self?.readerSession?.restartPolling()
                        } else {
                            self?.connectedTag.send(.error(nfcError)) // Complere subscription and invoke error handler
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
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        let nfcError = error as! NFCReaderError
        tagTimer?.invalidate()
        sessionTimer?.invalidate()        
        readerSessionError.send(nfcError)
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
                self?.connectedTag.send(.tag(tag7816))
            }
        }
    }
}

@available(iOS 13.0, *)
extension NFCReader: NFCReaderText {
    public var alertMessage: String {
        get { return readerSession?.alertMessage ?? "" }
        set { readerSession?.alertMessage = newValue }
    }
}

@available(iOS 13.0, *)
extension NFCReader: NFCReaderSessionAdapter {
    func restartPolling() {
        guard let session = readerSession, session.isReady else { return }
        
        DispatchQueue.global().async {
            self.tagTimer?.invalidate()
        }
        
        session.restartPolling()
    }
}
