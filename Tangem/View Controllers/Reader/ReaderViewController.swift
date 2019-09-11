//
//  ViewController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import UIKit
import TangemKit

class ReaderViewController: UIViewController, TestCardParsingCapable, DefaultErrorAlertsCapable {
    
    var customPresentationController: CustomPresentationController?
    
    let operationQueue = OperationQueue()
    
    lazy var tangemSession = {
        return TangemSession(delegate: self)
    }()
    
    
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var hintLabel: UILabel! {
        didSet {
            hintLabel.font = UIFont.tgm_maaxFontWith(size: 16.0, weight: .medium)
        }
    }
    
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var warningLabelButton: UIButton!
    @IBOutlet weak var scanButton: UIButton! {
        didSet {
            scanButton.layer.cornerRadius = 30.0
            scanButton.titleLabel?.font = UIFont.tgm_sairaFontWith(size: 20, weight: .bold)
            
            scanButton.setTitle(Localizations.scanButtonTitle, for: .normal)
            
            scanButton.layer.shadowRadius = 5.0
            scanButton.layer.shadowOffset = CGSize(width: 0, height: 5)
            scanButton.layer.shadowColor = UIColor.black.cgColor
            scanButton.layer.shadowOpacity = 0.08
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.hintLabel.text = Localizations.readerHintDefault
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        _ = {
            self.showFeatureRestrictionAlertIfNeeded()
        }()
    }
    
    // MARK: Actions
    
    @IBAction func infoButtonPressed(_ sender: Any) {
        UIView.animate(withDuration: 0.3) {
            self.infoButton.alpha = fabs(self.infoButton.alpha - 1)
            self.warningLabel.alpha = fabs(self.warningLabel.alpha - 1)
        }
    }
    
    @IBAction func scanButtonPressed(_ sender: Any) {
        #if targetEnvironment(simulator)
        showSimulationSheet()
        #else
        tangemSession.start()
        #endif
    }
    
    /* @IBAction func moreButtonPressed(_ sender: Any) {
     guard let viewController = self.storyboard?.instantiateViewController(withIdentifier: "ReaderMoreViewController") as? ReaderMoreViewController else {
     return
     }
     
     viewController.contentText = "Tangem for iOS\nVersion \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")!)"
     
     let presentationController = CustomPresentationController(presentedViewController: viewController, presenting: self)
     self.customPresentationController = presentationController
     viewController.preferredContentSize = CGSize(width: self.view.bounds.width, height: 247)
     viewController.transitioningDelegate = presentationController
     self.present(viewController, animated: true, completion: nil)
     }*/
    
    func launchSimulationParsingOperationWith(payload: Data) {
        tangemSession.payload = payload
        tangemSession.start()
    }
}

extension ReaderViewController : TangemSessionDelegate {
    
    func tangemSessionDidRead(card: Card) {
        guard card.isBlockchainKnown /*&& !card.isTestBlockchain*/ else {
            handleUnknownBlockchainCard()
            DispatchQueue.main.async {
                self.hintLabel.text = Localizations.readerHintDefault
            }
            return
        }
        
        switch card.genuinityState {
        case .pending:
            self.hintLabel.text = Localizations.readerHintScan
        case .nonGenuine:
            handleNonGenuineTangemCard(card) {
                UIApplication.navigationManager().showCardDetailsViewControllerWith(cardDetails: card)
            }
        case .genuine:
            UIApplication.navigationManager().showCardDetailsViewControllerWith(cardDetails: card)
        }
    }
    
    func tangemSessionDidFailWith(error: TangemSessionError) {
        switch error {
        case .locked:
            handleCardParserLockedCard()
        case .payloadError:
            handleCardParserWrongTLV()
        case .readerSessionError:
            handleReaderSessionError()
        }
        
        DispatchQueue.main.async {
            self.hintLabel.text = Localizations.readerHintDefault
        }
    }
    
}
