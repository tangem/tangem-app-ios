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

/// Provides NFC communication between an application and Tangem card.
@available(iOS 13.0, *)
final class NFCReader: NSObject {
    static let tagTimeout = 18.0
    static let idleTimeout = 2.0
    static let sessionTimeout = 52.0
    static let nfcStuckTimeout = 5.0
    static let retryCount = 10
    static let timestampTolerance = 2.0
    
    private(set) var tag: CurrentValueSubject<NFCTagType?, TangemSdkError> = .init(nil)
    let enableSessionInvalidateByTimer = true
    
    private let loggingEnabled = true
    private var connectedTag: NFCTag? = nil
    private var readerSessionError: TangemSdkError? = nil
    private var readerSession: NFCTagReaderSession?
    private var currentRetryCount = NFCReader.retryCount
    private var requestTimestamp: Date?
    private var cancelled: Bool = false
    private let lock = DispatchSemaphore(value: 1)
    
    /// Workaround for session timeout error (60 sec)
    private var sessionTimer: TangemTimer!
    /// Workaround for tag timeout connection error (20 sec)
    private var tagTimer: TangemTimer!
    /// Workaround for nfc stuck
    private var nfcStuckTimer: TangemTimer!
    // Idle timer
    private var idleTimer: TangemTimer!
    
    /// Invalidate session before session will close automatically
    @objc private func timerTimeout() {
        guard let session = readerSession,
            session.isReady else { return }
        
        stopSession(with: Localization.nfcSessionTimeout)
        readerSessionError = .nfcTimeout
    }
    
    private func stopTimers() {
        TangemTimer.stopTimers([sessionTimer, tagTimer, nfcStuckTimer, idleTimer])
    }
    
    override init() {
        super.init()
        sessionTimer = TangemTimer(timeInterval: NFCReader.sessionTimeout, completion: timerTimeout)
        tagTimer = TangemTimer(timeInterval: NFCReader.tagTimeout, completion: timerTimeout)
        nfcStuckTimer = TangemTimer(timeInterval: NFCReader.nfcStuckTimeout, completion: {[weak self] in
            self?.stopSession()
            self?.readerSessionError = .nfcStuck
        })
        idleTimer = TangemTimer(timeInterval: NFCReader.idleTimeout, completion: {[weak self] in
            self?.log("restart by idle timer")
            self?.restartPolling()
        })
    }
    
    private func log(_ message: String) {
        if loggingEnabled {
            print(message)
        }
    }
}

@available(iOS 13.0, *)
extension NFCReader: CardReader {    
    var isReady: Bool {
        return readerSession?.isReady ?? false
    }
    
    var alertMessage: String {
        get { return readerSession?.alertMessage ?? "" }
        set { readerSession?.alertMessage = newValue }
    }
    
    /// Start session and try to connect with tag
    func startSession(with message: String?) {
        if let existingSession = readerSession, existingSession.isReady { return }
        readerSessionError = nil
        connectedTag = nil
        readerSession = NFCTagReaderSession(pollingOption: [.iso14443, .iso15693], delegate: self)!
        readerSession!.alertMessage = message ?? Localization.nfcAlertDefault
        readerSession!.begin()
        nfcStuckTimer.start()
    }
    
    func stopSession(with errorMessage: String? = nil) {
        stopTimers()
        readerSessionError = nil
        connectedTag = nil
        if let errorMessage = errorMessage {
            readerSession?.invalidate(errorMessage: errorMessage)
        } else {
            readerSession?.invalidate()
        }
    }
    
    func restartPolling() {
        lock.wait()
        defer {lock.signal()}
        guard let session = readerSession, session.isReady, connectedTag != nil else { return }
        tagTimer.stop()
        idleTimer.stop()
        readerSessionError = nil
        connectedTag = nil
        log("Restart polling")
        tag.send(nil)
        session.restartPolling()
    }
    
    /// Send apdu command to connected tag
    /// - Parameter apdu: serialized apdu
    /// - Parameter completion: result with ResponseApdu or NFCError otherwise
    func send(apdu: CommandApdu, completion: @escaping (Result<ResponseApdu, TangemSdkError>) -> Void)   {
        idleTimer.stop()
        
        if let error = readerSessionError {
            completion(.failure(error))
            return
        }
        
        guard let connectedTag = connectedTag else {
            completion(.failure(.tagLost))
            return
        }
        
        guard case let .iso7816(tag) = connectedTag else {
            completion(.failure(.unsupportedCommand))
            return
        }
     
        requestTimestamp = Date()
        tag.sendCommand(apdu: NFCISO7816APDU(apdu)) {[weak self] (data, sw1, sw2, error) in
            guard let self = self,
                let session = tag.session,
                session.isReady else {
                    return
            }
           
            self.log("receive response")
            guard !self.cancelled else {
                self.log("skip cancelled")
                return
            }
            
            if error != nil {
                if let requestTimestamp = self.requestTimestamp,
                    requestTimestamp.distance(to: Date()) > NFCReader.timestampTolerance {
                    self.log("invoke restart polling by timestamp")
                    self.restartPolling()
                    return
                }
                
                if self.currentRetryCount > 0 {
                    self.currentRetryCount -= 1
                    self.log("retry")
                    self.send(apdu: apdu, completion: completion)
                } else {
                    self.log("invoke restart by retry count")
                    self.restartPolling()
                }
                
            } else {
                self.log("success response")
                self.idleTimer.start()
                self.currentRetryCount = NFCReader.retryCount
                let responseApdu = ResponseApdu(data, sw1 ,sw2)
                completion(.success(responseApdu))                
            }
        }
    }
    
    func readSlix2Tag(completion: @escaping (Result<ResponseApdu, TangemSdkError>) -> Void) {
        if let error = readerSessionError {
            completion(.failure(error))
            return
        }
        
        guard let connectedTag = connectedTag else {
            completion(.failure(.tagLost))
            return
        }
        
        guard case let .iso15693(tag) = connectedTag else {
            completion(.failure(.unsupportedCommand))
            return
        }
        
        tag.readMultipleBlocks(requestFlags: [.highDataRate], blockRange: NSRange(location: 0, length: 40)) { [weak self] data1, error in
            guard let self = self,
                let session = self.readerSession,
                session.isReady else {
                    return
            }

            if let error = error as NSError? {
                print(error.userInfo)
                self.readSlix2Tag(completion: completion)
                print(error.localizedDescription)
            } else {
                tag.readMultipleBlocks(requestFlags: [.highDataRate], blockRange: NSRange(location: 40, length: 38)) {[weak self] data2, error in
                    guard let self = self,
                        let session = self.readerSession,
                        session.isReady else {
                            return
                    }
                    
                    if let error = error as NSError? {
                        print(error.userInfo)
                        self.readSlix2Tag(completion: completion)
                        print(error.localizedDescription)
                    } else {
                        let jonedData = Data((data1 + data2).joined())
                        if let responseApdu = ResponseApdu(slix2Data: jonedData)  {
                            completion(.success(responseApdu))
                        } else {
                            if self.currentRetryCount > 0 {
                                self.log("retry")
                                self.currentRetryCount -= 1
                                self.readSlix2Tag(completion: completion)
                            } else {
                                self.log("invoke restart by retry count")
                                self.restartPolling()
                            }
                        }
                        
                    }
                }
            }
        }
    }
}

@available(iOS 13.0, *)
extension NFCReader: NFCTagReaderSessionDelegate {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        nfcStuckTimer.stop()
        sessionTimer.start()
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        cancelled = true
        readerSession = nil
        stopTimers()
        let nfcError = error as! NFCReaderError
        print(nfcError.localizedDescription)
        readerSessionError = TangemSdkError.parse(nfcError)
        tag.send(completion: .failure(readerSessionError!))
        tag = .init(nil)
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        currentRetryCount = NFCReader.retryCount
        cancelled = false
        let nfcTag = tags.first!
        session.connect(to: nfcTag) {error in
            guard error == nil else {
                session.restartPolling()
                return
            }
            
            self.tagTimer.start()
            self.connectedTag = nfcTag
            let tagType = self.getTagType(nfcTag)
            self.tag.send(tagType)
            
            if case .tag = tagType {
                self.idleTimer.start()
            }
        }
    }
    
    private func getTagType(_ nfcTag: NFCTag) -> NFCTagType {
        switch nfcTag {
        case .iso7816(let iso7816Tag):
            return .tag(uid: iso7816Tag.identifier)
        case .iso15693:
            return .slix2
        default:
            return .unknown
        }
    }
}
