//
//  NavigationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation

class NavigationManager {
    
    public private(set) var navigationController: UINavigationController = {
        let navigationController = UINavigationController()
        navigationController.isNavigationBarHidden = true
        return navigationController
    }()
    
    init(rootViewController: UIViewController) {
        navigationController.viewControllers = [rootViewController]
    }
    
    func showCardDetailsViewControllerWith(cardDetails: Card) {
        let storyBoard = UIStoryboard(name: "Card", bundle: nil)
        guard let cardDetailsViewController = storyBoard.instantiateViewController(withIdentifier: "CardDetailsViewController") as? CardDetailsViewController else {
            return
        }
        
        cardDetailsViewController.cardDetails = cardDetails
        
        navigationController.pushViewController(cardDetailsViewController, animated: true)
    }
    
}
