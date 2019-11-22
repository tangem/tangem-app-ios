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
enum NFCTagWrapper {
    case tag(NFCISO7816Tag)
    case error(NFCReaderError)
}

/// Provides NFC communication between an application and Tangem card.
@available(iOS 13.0, *)
public final class NFCReader: NSObject {
    static let tagTimeout = 19.0
    static let sessionTimeout = 59.0
    static let retryCount = 10
    public let enableSessionInvalidateByTimer = true
    
    private let connectedTag = CurrentValueSubject<NFCTagWrapper?,Never>(nil)
    private let readerSessionError = CurrentValueSubject<NFCReaderError?,Never>(nil)
    private var readerSession: NFCTagReaderSession?
    private var sessionSubscription: AnyCancellable?
    private var tagSubscription: AnyCancellable?
    private var currentRetryCount = NFCReader.retryCount
    
    /// Workaround for session timeout error (60 sec)
    private var sessionTimer: Timer?
    
    /// Workaround for tag timeout connection error (20 sec)
    private var tagTimer: Timer?
    private func startSessionTimer() {
        guard enableSessionInvalidateByTimer else { return }
        DispatchQueue.main.async {
            self.sessionTimer?.invalidate()
            self.sessionTimer = Timer.scheduledTimer(timeInterval: NFCReader.sessionTimeout, target: self, selector: #selector(self.timerTimeout), userInfo: nil, repeats: false)
        }
    }
    
    private func startTagTimer() {
        guard enableSessionInvalidateByTimer else { return }
        
        DispatchQueue.main.async {
            self.tagTimer?.invalidate()
            self.tagTimer = Timer.scheduledTimer(timeInterval: NFCReader.tagTimeout, target: self, selector: #selector(self.timerTimeout), userInfo: nil, repeats: false)
        }
    }
    
    
    /// Invalidate session before session will close automatically
    @objc private func timerTimeout() {
        guard let session = readerSession,
            session.isReady else { return }
        
        stopSession(errorMessage: Localization.nfcSessionTimeout)
        readerSessionError.send(NFCReaderError(.readerSessionInvalidationErrorSessionTimeout))
    }
    
    private func stopTimers() {
        DispatchQueue.main.async {
            self.sessionTimer?.invalidate()
            self.tagTimer?.invalidate()
        }
    }
}

@available(iOS 13.0, *)
extension NFCReader: CardReader {
    public var alertMessage: String {
        get { return readerSession?.alertMessage ?? "" }
        set { readerSession?.alertMessage = newValue }
    }
    
    /// Start session and try to connect with tag
    public func startSession() {
        if let existingSession = readerSession, existingSession.isReady { return }
        readerSessionError.send(nil)
        connectedTag.send(nil)
        
        readerSession = NFCTagReaderSession(pollingOption: .iso14443, delegate: self)!
        readerSession!.alertMessage = Localization.nfcAlertDefault
        readerSession!.begin()
    }
    
    public func stopSession() {
        stopTimers()
        readerSessionError.send(nil)
        connectedTag.send(nil)
        readerSession?.invalidate()
        readerSession = nil
    }
    
    public func stopSession(errorMessage: String) {
        stopTimers()
        readerSessionError.send(nil)
        connectedTag.send(nil)
        readerSession?.invalidate(errorMessage: errorMessage)
        readerSession = nil
    }
    
    /// Send apdu command to connected tag
    /// - Parameter command: serialized apdu
    /// - Parameter completion: result with ResponseApdu or NFCReaderError otherwise
    public func send(commandApdu: CommandApdu, completion: @escaping (Result<ResponseApdu, NFCReaderError>) -> Void) {
        sessionSubscription = readerSessionError
            .compactMap { $0 }
            .sink(receiveValue: { [weak self] error in
                completion(.failure(error))
                self?.cancelSubscriptions()
            })

        tagSubscription = connectedTag
            .compactMap({ $0 })
            .sink(receiveValue: { [weak self] tagWrapper in
                switch tagWrapper {
                case .error(let tagError):
                    completion(.failure(tagError))
                    self?.cancelSubscriptions()
                case .tag(let tag):
                    let apdu = NFCISO7816APDU(commandApdu)
                    self?.sendCommand(apdu: apdu, to: tag, completion: completion)
                }
            })
    }
    
    public func restartPolling() {
        guard let session = readerSession, session.isReady else { return }
        
        readerSessionError.send(nil)
        connectedTag.send(nil)
        
        DispatchQueue.main.async {
            self.tagTimer?.invalidate()
        }
        print("Restart polling")
        session.restartPolling()
    }
    
    private func sendCommand(apdu: NFCISO7816APDU, to tag: NFCISO7816Tag, completion: @escaping (Result<ResponseApdu, NFCReaderError>) -> Void) {
        tag.sendCommand(apdu: apdu) {[weak self] (data, sw1, sw2, error) in
            guard let self = self,
                let session = self.readerSession,
                session.isReady else {
                    return
            }

            if error != nil {
                if self.currentRetryCount > 0 {
                    self.currentRetryCount -= 1
                    self.readerSession?.sessionQueue.async {
                        self.sendCommand(apdu: apdu, to: tag, completion: completion)
                    }
                } else {
                    self.currentRetryCount = NFCReader.retryCount
                    self.readerSession?.restartPolling()
                }
            } else {
                self.currentRetryCount = NFCReader.retryCount
                let responseApdu = ResponseApdu(data, sw1 ,sw2)
                self.cancelSubscriptions()
                completion(.success(responseApdu))
            }
        }
    }
    
    private func cancelSubscriptions() {
        sessionSubscription?.cancel()
        tagSubscription?.cancel()
    }
   
}

@available(iOS 13.0, *)
extension NFCReader: NFCTagReaderSessionDelegate {
    public func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        startSessionTimer()
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        stopTimers()
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
