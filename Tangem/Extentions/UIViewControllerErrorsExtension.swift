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
    func handleNonGenuineTangemCard(_ card: CardViewModel, completion: @escaping () -> Void)
    func handleUntrustedCard()
    func handleTXSendError(message: String)
    func handleTXBuildError()
    func handleFeeOutadatedError()
    func handleSuccess(completion: @escaping () -> Void)
    func handleTXNotSignedByIssuer()
    func handleGenericError(_ error: Error, completion: (() -> Void)?)
    func handleStart2CoinLoad()
    func handleOldDevice(completion: @escaping () -> Void)
}

extension DefaultErrorAlertsCapable where Self: UIViewController {
    
    func handleCardParserWrongTLV(completion: @escaping () -> Void = {}) {
        let validationAlert = UIAlertController(title: Localizations.generalError, message: Localizations.alertParseFailed, preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: Localizations.ok, style: .default, handler: { (_) in
            completion()
        }))
        self.present(validationAlert, animated: true, completion: nil)
    }
    
    func handleCardParserLockedCard(completion: @escaping () -> Void = {}) {
        let validationAlert = UIAlertController(title: Localizations.dialogWarning, message: Localizations.alertReadProtected, preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: Localizations.ok, style: .default, handler: { (_) in
            completion()
        }))
        self.present(validationAlert, animated: true, completion: nil)
    }
    
    func handleReaderSessionError(completion: @escaping () -> Void = {}) {
        let validationAlert = UIAlertController(title: Localizations.generalError, message: Localizations.alertNfcGeneric, preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: Localizations.ok, style: .default, handler: { (_) in
            completion()
        }))
        self.present(validationAlert, animated: true, completion: nil)
    }
    
    func handleNonGenuineTangemCard(_ card: CardViewModel, completion: @escaping () -> Void = {}) {
        let validationAlert = UIAlertController(title: Localizations.dialogWarning, message: Localizations.alertFailedAttest, preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: Localizations.ok, style: .default, handler: { (_) in
            completion()
        }))
        self.present(validationAlert, animated: true, completion: nil)
    }
    
    func handleUnknownBlockchainCard(_ completion: @escaping () -> Void = {}) {
        let alert = UIAlertController(title: Localizations.dialogWarning, message: Localizations.alertUnknownBlockchain, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localizations.ok, style: .default, handler: { (_) in
            completion()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func handleUntrustedCard() {
        let alert = UIAlertController(title: Localizations.dialogWarning, message: Localizations.loadedWalletWarningCardSignedTransactions, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localizations.ok, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func handleTXSendError(message: String) {
        let validationAlert = UIAlertController(title: Localizations.generalError, message: Localizations.sendTransactionErrorFailedToSend(message), preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: Localizations.ok, style: .default, handler: nil))
        self.present(validationAlert, animated: true, completion: nil)
    }
    
    func handleTXBuildError() {
        let validationAlert = UIAlertController(title: Localizations.generalError, message: Localizations.alertFailedBuildTx, preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: Localizations.ok, style: .default, handler: nil))
        self.present(validationAlert, animated: true, completion: nil)
    }
    
    func handleTXNotSignedByIssuer() {
        let validationAlert = UIAlertController(title: Localizations.generalError, message: Localizations.alertNoIssuerSign, preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: Localizations.ok, style: .default, handler: nil))
        self.present(validationAlert, animated: true, completion: nil)
    }
    
    func handleFeeOutadatedError() {
        let validationAlert = UIAlertController(title: Localizations.dialogWarning, message: Localizations.confirmTransactionErrorDataIsOutdated, preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: Localizations.ok, style: .default, handler: nil))
        self.present(validationAlert, animated: true, completion: nil)
    }
    
    func handleSuccess(completion: @escaping () -> Void = {}) {
        let validationAlert = UIAlertController(title: Localizations.success, message: Localizations.sendTransactionSuccess, preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: Localizations.ok, style: .default, handler: { (_) in
            completion()
        }))
        self.present(validationAlert, animated: true, completion: nil)
        
    }
    
    func handleGenericError(_ error: Error, completion: (() -> Void)? = nil) {
        let message = error as?  String ?? error.localizedDescription
        let validationAlert = UIAlertController(title: Localizations.generalError, message: message, preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: Localizations.ok, style: .default, handler: { (_) in
            completion?()
        }))
        self.present(validationAlert, animated: true, completion: nil)
    }
    
    func handleStart2CoinLoad() {
        let alert = UIAlertController(title: Localizations.dialogWarning, message: Localizations.alertStart2CoinMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localizations.generalCancel, style: .default, handler: { (_) in
        }))
        alert.addAction(UIAlertAction(title: Localizations.goToLink, style: .default, handler: { (_) in
            let url = URL(string: "https://www.google.com")!
            UIApplication.shared.open(url, options: [:], completionHandler: nil)        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func handleOldDevice(completion: @escaping () -> Void = {}) {
        let validationAlert = UIAlertController(title: Localizations.dialogWarning, message: Localizations.oldDeviceForThisCard, preferredStyle: .alert)
           validationAlert.addAction(UIAlertAction(title: Localizations.ok, style: .default, handler: { (_) in
               completion()
           }))
           self.present(validationAlert, animated: true, completion: nil)
       }
}
