//
//  UIViewControllerFeaturesAlertExtension.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import UIKit

extension UserDefaults {
    
    private struct Constants {
        static let kIsFeaturesRestrictionAlertDismissed = "kIsFeaturesRestrictionAlertDismissed"  
    }
    
    func isFeaturesRestrictionAlertDismissed() -> Bool {
        return self.bool(forKey: Constants.kIsFeaturesRestrictionAlertDismissed)
    }
    
    func setIsFeaturesRestrictionAlertDismissed(_ shouldShow: Bool) {
        self.set(shouldShow, forKey: Constants.kIsFeaturesRestrictionAlertDismissed)
    }
    
}

extension UIViewController {
    
    func showFeatureRestrictionAlertIfNeeded() {
        if #available(iOS 13.0, *)  {
            return
        }
        
        guard !UserDefaults.standard.isFeaturesRestrictionAlertDismissed() else {
            return
        }
        
        let validationAlert = UIAlertController(title: Localizations.disclamerNfcTitle,
                                                message: Localizations.disclamerNfcMessage, preferredStyle: .alert)
        
        validationAlert.addAction(UIAlertAction(title: Localizations.disclamerNfcOk, style: .default, handler: nil))
        validationAlert.addAction(UIAlertAction(title: Localizations.disclamerNfcNotShow, style: .default, handler: { (_) in
            UserDefaults.standard.setIsFeaturesRestrictionAlertDismissed(true)
        }))
        validationAlert.addAction(UIAlertAction(title: Localizations.moreInfo, style: .cancel, handler: { (_) in
            let url = URL(string: "http://tangem.com/faq")!
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }))
        
        self.present(validationAlert, animated: true, completion: nil)
    }
    
}
