//
//  UIViewControllerErrorsExtension.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation
import TangemKit

protocol DefaultErrorAlertsCapable {

    func handleCardParserWrongTLV(completion: @escaping () -> Void)
    func handleCardParserLockedCard(completion: @escaping () -> Void)
    func handleReaderSessionError(completion: @escaping () -> Void)
    func handleNonGenuineTangemCard(_ card: Card, completion: @escaping () -> Void)

}

extension DefaultErrorAlertsCapable where Self: UIViewController {

    func handleCardParserWrongTLV(completion: @escaping () -> Void = {}) {
        let validationAlert = UIAlertController(title: "Error", message: "Failed to parse data received from the banknote", preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
            completion()
        }))
        self.present(validationAlert, animated: true, completion: nil)
    }

    func handleCardParserLockedCard(completion: @escaping () -> Void = {}) {
        let validationAlert = UIAlertController(title: "Info", message: "This app can’t read protected Tangem banknotes", preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
            completion()
        }))
        self.present(validationAlert, animated: true, completion: nil)
    }

    func handleReaderSessionError(completion: @escaping () -> Void = {}) {
        let validationAlert = UIAlertController(title: "Error", message: "NFC reader invalidated with error", preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
            completion()
        }))
        self.present(validationAlert, animated: true, completion: nil)
    }

    func handleNonGenuineTangemCard(_ card: Card, completion: @escaping () -> Void = {}) {
        let validationAlert = UIAlertController(title: "Error", message: "Warning: your iPhone device does not allow to attest the card. Please check elsewhere if possible.", preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
            completion()
        }))
        self.present(validationAlert, animated: true, completion: nil)
    }
    
    func handleUnknownBlockchainCard(_ completion: @escaping () -> Void = {}) {
        let alert = UIAlertController(title: "Warning", message: "This card is not supported", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
            completion()
        }))
        self.present(alert, animated: true, completion: nil)
    }

}
