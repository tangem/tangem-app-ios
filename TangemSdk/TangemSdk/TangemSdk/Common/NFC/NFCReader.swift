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
    case slix2Tag(NFCISO15693Tag)
    case error(NFCReaderError)
}

/// Provides NFC communication between an application and Tangem card.
@available(iOS 13.0, *)
public final class NFCReader: NSObject {
    public var tagDidConnect: (() -> Void)?
    
    static let tagTimeout = 18.0
    static let sessionTimeout = 52.0
    static let nfcStuckTimeout = 5.0
    static let retryCount = 10
    static let timestampTolerance = 2.0
    private let loggingEnabled = true
    
    public let enableSessionInvalidateByTimer = true
    
    private let connectedTag = CurrentValueSubject<NFCTagWrapper?,Never>(nil)
    private let readerSessionError = CurrentValueSubject<TaskError?,Never>(nil)
    private var readerSession: NFCTagReaderSession?
    private var disposeBag: [AnyCancellable]?
    private var currentRetryCount = NFCReader.retryCount
    private var requestTimestamp: Date?
    private var cancelled: Bool = false
    
    /// Workaround for session timeout error (60 sec)
    private var sessionTimer: TangemTimer!
    /// Workaround for tag timeout connection error (20 sec)
    private var tagTimer: TangemTimer!
    /// Workaround for nfc stuck
    private var nfcStuckTimer: TangemTimer!
    
    /// Invalidate session before session will close automatically
    @objc private func timerTimeout() {
        guard let session = readerSession,
            session.isReady else { return }
        
        stopSession(with: Localization.nfcSessionTimeout)
        readerSessionError.send(TaskError.nfcTimeout)
    }
    
    private func stopTimers() {
        TangemTimer.stopTimers([sessionTimer, tagTimer, nfcStuckTimer])
    }
    
    override init() {
        super.init()
        sessionTimer = TangemTimer(timeInterval: NFCReader.sessionTimeout, completion: timerTimeout)
        tagTimer = TangemTimer(timeInterval: NFCReader.tagTimeout, completion: timerTimeout)
        nfcStuckTimer = TangemTimer(timeInterval: NFCReader.nfcStuckTimeout, completion: {[weak self] in
            self?.stopSession()
            self?.readerSessionError.send(TaskError.nfcStuck)
        })
    }
    
    private func cancelSubscriptions() {
        disposeBag?.forEach{ $0.cancel() }
        disposeBag = nil
    }
    
    private func log(_ message: String) {
        if loggingEnabled {
            print(message)
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
    public func startSession(with message: String?) {
        if let existingSession = readerSession, existingSession.isReady { return }
        readerSessionError.send(nil)
        connectedTag.send(nil)
        
        readerSession = NFCTagReaderSession(pollingOption: [.iso14443, .iso15693], delegate: self)!
        readerSession!.alertMessage = message ?? Localization.nfcAlertDefault
        readerSession!.begin()
        nfcStuckTimer.start()
    }
    
    public func stopSession(with errorMessage: String? = nil) {
        stopTimers()
        readerSessionError.send(nil)
        connectedTag.send(nil)
        if let errorMessage = errorMessage {
            readerSession?.invalidate(errorMessage: errorMessage)
        } else {
            readerSession?.invalidate()
        }
        readerSession = nil
    }
    
    /// Send apdu command to connected tag
    /// - Parameter command: serialized apdu
    /// - Parameter completion: result with ResponseApdu or NFCError otherwise
    public func send(commandApdu: CommandApdu, completion: @escaping (Result<ResponseApdu, TaskError>) -> Void) {
        let sessionSubscription = readerSessionError
            .compactMap { $0 }
            .sink(receiveValue: { [weak self] error in
                completion(.failure(error))
                self?.cancelSubscriptions()
            })
        
        let tagSubscription = connectedTag
            .compactMap({ $0 })
            .sink(receiveValue: { [weak self] tagWrapper in
                switch tagWrapper {
                case .error(let tagError):
                    print(tagError.localizedDescription)
                    completion(.failure(TaskError.parse(tagError)))
                    self?.cancelSubscriptions()
                case .tag(let tag):
                    let apdu = NFCISO7816APDU(commandApdu)
                    self?.sendCommand(apdu: apdu, to: tag, completion: completion)
                case .slix2Tag(let tag):
                    self?.readSlix2Tag(tag, completion: completion)
                }
            })
        
        disposeBag = [sessionSubscription, tagSubscription]
    }
    
    public func restartPolling() {
        guard let session = readerSession, session.isReady else { return }
        
        readerSessionError.send(nil)
        connectedTag.send(nil)
        tagTimer.stop()
        log("Restart polling")
        session.restartPolling()
    }
    
    private func sendCommand(apdu: NFCISO7816APDU, to tag: NFCISO7816Tag, completion: @escaping (Result<ResponseApdu, TaskError>) -> Void) {
        requestTimestamp = Date()
        tag.sendCommand(apdu: apdu) {[weak self] (data, sw1, sw2, error) in
            guard let self = self,
                let session = self.readerSession,
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
                    self.sendCommand(apdu: apdu, to: tag, completion: completion)
                } else {
                    self.log("invoke restart by retry count")
                    self.restartPolling()
                }
                
            } else {
                self.log("success response")
                self.currentRetryCount = NFCReader.retryCount
                let responseApdu = ResponseApdu(data, sw1 ,sw2)
                self.cancelSubscriptions()
                completion(.success(responseApdu))
            }
        }
    }
    
    private func readSlix2Tag(_ tag: NFCISO15693Tag, completion: @escaping (Result<ResponseApdu, TaskError>) -> Void) {
        tag.readMultipleBlocks(requestFlags: [.highDataRate], blockRange: NSRange(location: 0, length: 40)) { [weak self] data1, error in
            guard let self = self,
                let session = self.readerSession,
                session.isReady else {
                    return
            }
            
            if let error = error as NSError? {
                print(error.userInfo)
                self.readSlix2Tag(tag, completion: completion)
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
                        self.readSlix2Tag(tag, completion: completion)
                        print(error.localizedDescription)
                    } else {
                        let jonedData = Data((data1 + data2).joined())
                        if let responseApdu = ResponseApdu(slix2Data: jonedData)  {
                            self.cancelSubscriptions()
                            completion(.success(responseApdu))
                        } else {
                            if self.currentRetryCount > 0 {
                                self.log("retry")
                                self.currentRetryCount -= 1
                                self.readSlix2Tag(tag, completion: completion)
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
    public func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        nfcStuckTimer.stop()
        sessionTimer.start()
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        cancelled = true
        stopTimers()
        let nfcError = error as! NFCReaderError
        print(nfcError.localizedDescription)
        readerSessionError.send(TaskError.parse(nfcError))
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        tagDidConnect?()
        currentRetryCount = NFCReader.retryCount
        cancelled = false
        let nfcTag = tags.first!
        session.connect(to: nfcTag) {[weak self] error in
            guard error == nil else {
                session.restartPolling()
                return
            }
            self?.tagTimer.start()
            switch nfcTag {
            case .iso7816(let tag7816):
                self?.connectedTag.send(.tag(tag7816))
            case .iso15693(let tag15693):
                self?.connectedTag.send(.slix2Tag(tag15693))
            default:
                fatalError("Unsupported tag")
            }
        }
    }
}
