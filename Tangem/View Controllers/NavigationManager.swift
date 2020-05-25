//
//  NavigationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation

class NavigationManager {
    public var rootViewController: ReaderViewController? {
        return navigationController.viewControllers.first as? ReaderViewController
    }
    
    public private(set) var navigationController: UINavigationController = {
        let navigationController = UINavigationController()
        navigationController.isNavigationBarHidden = true
        return navigationController
    }()
    
    init(rootViewController: UIViewController) {
        navigationController.viewControllers = [rootViewController]
    }
    
    func showCardDetailsViewControllerWith(cardDetails: CardViewModel) {
        let storyBoard = UIStoryboard(name: "Card", bundle: nil)
        guard let cardDetailsViewController = storyBoard.instantiateViewController(withIdentifier: "CardDetailsViewController") as? CardDetailsViewController else {
            return
        }
        
        cardDetailsViewController.card = cardDetails
        
        navigationController.pushViewController(cardDetailsViewController, animated: true)
    }
    
    @available(iOS 13.0, *)
    func showIdDetailsViewControllerWith(cardDetails: CardViewModel) {
        let storyBoard = UIStoryboard(name: "Card", bundle: nil)
        guard let cardDetailsViewController = storyBoard.instantiateViewController(withIdentifier: "IdDetailsViewController") as? IdDetailsViewController else {
            return
        }
        
        cardDetailsViewController.card = cardDetails
        
        navigationController.pushViewController(cardDetailsViewController, animated: true)
    }
}
