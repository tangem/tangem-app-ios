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
    func handleUntrustedCard()
    func handleTXSendError()
    func handleTXBuildError()
    func handleFeeOutadatedError()
    func handleSuccess(completion: @escaping () -> Void)
    func handleTXNotSignedByIssuer()
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
        let validationAlert = UIAlertController(title: "Warning", message: "Your iPhone device does not allow to attest the card. Please check elsewhere if possible.", preferredStyle: .alert)
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
    
    func handleUntrustedCard() {
        let alert = UIAlertController(title: "Warning", message: "This card has been already topped up and signed transactions in the past. Consider immediate withdrawal of all funds if you have received this card from an untrusted source", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func handleTXSendError() {
        let validationAlert = UIAlertController(title: "Error", message: "Transaction wasn't sent to the blockchain", preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(validationAlert, animated: true, completion: nil)
    }
    
    func handleTXBuildError() {
           let validationAlert = UIAlertController(title: "Error", message: "Can't build transaction with provided data. Please, try to rescan card and try again", preferredStyle: .alert)
           validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
           self.present(validationAlert, animated: true, completion: nil)
       }
    
    func handleTXNotSignedByIssuer() {
              let validationAlert = UIAlertController(title: "Error", message: "Transaction must be signed by issuer", preferredStyle: .alert)
              validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
              self.present(validationAlert, animated: true, completion: nil)
          }
    
    func handleFeeOutadatedError() {
        let validationAlert = UIAlertController(title: "Warning", message: "The obtained data is outdated! Fee was updated", preferredStyle: .alert)
                  validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                  self.present(validationAlert, animated: true, completion: nil)
    }
    
    func handleSuccess(completion: @escaping () -> Void = {}) {
        let validationAlert = UIAlertController(title: "Success", message: "Transaction has been successfully signed and sent to blockchain node. Wallet balance will be updated in a while", preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
            completion()
        }))
        self.present(validationAlert, animated: true, completion: nil)
        
    }
}
