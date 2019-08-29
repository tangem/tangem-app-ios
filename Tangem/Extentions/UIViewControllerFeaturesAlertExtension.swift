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
        guard !UserDefaults.standard.isFeaturesRestrictionAlertDismissed() else {
            return
        }
        
        let validationAlert = UIAlertController(title: "Important: NFC restriction on iOS", 
                                                message: "You can only check balance and validity of Tangem card and receive funds to it due to iOS restrictions on data transfer via NFC", preferredStyle: .alert)
        
        validationAlert.addAction(UIAlertAction(title: "I understand", style: .default, handler: nil))
        validationAlert.addAction(UIAlertAction(title: "Don't show again", style: .default, handler: { (_) in
            UserDefaults.standard.setIsFeaturesRestrictionAlertDismissed(true)
        }))
        validationAlert.addAction(UIAlertAction(title: "More Info", style: .cancel, handler: { (_) in
            let url = URL(string: "http://tangem.com/faq")!
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }))
        
        self.present(validationAlert, animated: true, completion: nil)
    }
    
}
