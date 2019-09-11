//
//  TangemSession.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

public enum TangemSessionError: Error {
    case readerSessionError(error: Error)
    case payloadError
    case locked
}

public protocol TangemSessionDelegate: class {
    
    func tangemSessionDidRead(card: Card)
    func tangemSessionDidFailWith(error: TangemSessionError)
    
}

public class TangemSession {
    
    public var payload: Data?
    
    var isBusy: Bool {
        if #available(iOS 13.0, *), payload == nil {
            return readSession.isBusy
        } else {
            return scanner?.isBusy ?? false
        }
    }
    
    weak var delegate: TangemSessionDelegate?
    var card: Card?
    var scanner: CardScanner?
    
    @available(iOS 13.0, *)
    lazy var readSession: CardSession =  {
        let session = CardSession() {[weak self] result in
            switch result {
            case .success (let tlv):
                let card = Card(tags: Array(tlv.values))
                card.genuinityState = .genuine
                DispatchQueue.main.async {
                    self?.delegate?.tangemSessionDidRead(card: card)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.delegate?.tangemSessionDidFailWith(error: .readerSessionError(error:error))
                }
            }
        }
        return session
    }()
    
    public init(payload: Data? = nil, delegate: TangemSessionDelegate) {
        self.delegate = delegate
        self.payload = payload
    }
    
    public func invalidate() {
        scanner?.invalidate()
    }
    
    public func start() {
        guard !isBusy else {
            return
        }
        
        if #available(iOS 13.0, *), payload == nil {
            readSession.start()
        } else {
            startDoubleScanReadSession()
        }
    }
    
    private func startDoubleScanReadSession() {
        scanner = CardScanner(payload: payload, completion: { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .pending(let card):
                    self?.delegate?.tangemSessionDidRead(card: card)
                case .finished(let card):
                    self?.delegate?.tangemSessionDidRead(card: card)
                case .readerSessionError(let nfcError):
                    self?.delegate?.tangemSessionDidFailWith(error: .readerSessionError(error:nfcError))
                case .locked:
                    self?.delegate?.tangemSessionDidFailWith(error: .locked)
                case .tlvError:
                    self?.delegate?.tangemSessionDidFailWith(error: .payloadError)
                case .cardChanged:
                    self?.handleCardChanged()
                }
            }
        })
    }
    
    func handleCardChanged() {
        guard !isBusy else {
            return
        }
        
        start()
    }    
}
