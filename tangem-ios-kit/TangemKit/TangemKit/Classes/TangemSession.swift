//
//  TangemSession.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

public enum TangemSessionError: Error {
    case readerSessionError
    case payloadError
    case locked
}

public protocol TangemSessionDelegate: class {

    func tangemSessionDidRead(card: Card)
    func tangemSessionDidFailWith(error: TangemSessionError)

}

public class TangemSession {

    weak var delegate: TangemSessionDelegate?

    var payload: Data?
    var card: Card?
    var scanner: CardScanner?

    public init(payload: Data? = nil, delegate: TangemSessionDelegate) {
        self.delegate = delegate
        self.payload = payload
    }

    public func invalidate() {
        scanner?.invalidate()
    }

    public func start() {
        scanner?.invalidate()
        scanner = CardScanner(payload: payload, completion: { [weak self] (result) in
            switch result {
            case .pending(let card):
                self?.delegate?.tangemSessionDidRead(card: card)
            case .finished(let card):
                self?.delegate?.tangemSessionDidRead(card: card)
            case .readerSessionError:
                self?.delegate?.tangemSessionDidFailWith(error: .readerSessionError)
            case .locked:
                self?.delegate?.tangemSessionDidFailWith(error: .locked)
            case .tlvError:
                self?.delegate?.tangemSessionDidFailWith(error: .payloadError)
            case .cardChanged:
                self?.handleCardChanged()
            }
        })
    }

    func handleCardChanged() {
        invalidate()
        start()
    }

}
