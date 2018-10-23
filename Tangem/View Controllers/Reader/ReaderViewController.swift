//
//  ViewController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import UIKit

class ReaderViewController: UIViewController, TestCardParsingCapable {
    
    var customPresentationController: CustomPresentationController?
    
    let operationQueue = OperationQueue()
    var scanner: CardScanner?
    
    private struct Constants {
        static let hintLabelDefaultText = "Press Scan and touch banknote with your iPhone as shown above"
        static let hintLabelScanningText = "Hold the card close to the reader"
    }
    
    @IBOutlet weak var hintLabel: UILabel! {
        didSet {
            hintLabel.font = UIFont.tgm_maaxFontWith(size: 16.0, weight: .medium)
        }
    }
    
    @IBOutlet weak var scanButton: UIButton! {
        didSet {
            scanButton.layer.cornerRadius = 30.0
            scanButton.titleLabel?.font = UIFont.tgm_sairaFontWith(size: 20, weight: .bold)
            
            scanButton.layer.shadowRadius = 5.0
            scanButton.layer.shadowOffset = CGSize(width: 0, height: 5)
            scanButton.layer.shadowColor = UIColor.black.cgColor
            scanButton.layer.shadowOpacity = 0.08
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DispatchQueue.main.async {
            self.hintLabel.text = Constants.hintLabelDefaultText
        }
    }
    
    // MARK: Actions
    
    @IBAction func scanButtonPressed(_ sender: Any) {
        #if targetEnvironment(simulator)
        showSimulationSheet()
        #else
        initiateScan()
        #endif
    }
    
    func initiateScan() {
        scanner = CardScanner { (result) in
            switch result {
            case .success(let card):
                UIApplication.navigationManager().showCardDetailsViewControllerWith(cardDetails: card)
            case .readerSessionError(let error):
                print("\(error.localizedDescription)")
            case .locked:
                self.handleCardParserLockedCard()
            case .tlvError:
                self.handleCardParserWrongTLV()
            case .nonGenuineCard(let card):
                self.handleNonGenuineTangemCard(card)
            }
        }
        
        scanner?.initiateScan()
        hintLabel.text = Constants.hintLabelScanningText
    }
    
    @IBAction func moreButtonPressed(_ sender: Any) {
        guard let viewController = self.storyboard?.instantiateViewController(withIdentifier: "ReaderMoreViewController") as? ReaderMoreViewController else {
            return
        }
        
        viewController.contentText = "Tangem for iOS\nVersion \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")!)"
        
        let presentationController = CustomPresentationController(presentedViewController: viewController, presenting: self)
        self.customPresentationController = presentationController
        viewController.preferredContentSize = CGSize(width: self.view.bounds.width, height: 247)
        viewController.transitioningDelegate = presentationController
        self.present(viewController, animated: true, completion: nil)
    }
    
    func launchSimulationParsingOperationWith(payload: Data) {
        operationQueue.cancelAllOperations()
        
        let operation = CardParsingOperation(payload: payload) { (result) in
            switch result {
            case .success(let card):
                UIApplication.navigationManager().showCardDetailsViewControllerWith(cardDetails: card)
            case .locked:
                self.handleCardParserLockedCard()
            case .tlvError:
                self.handleCardParserWrongTLV()
            }
        }
        operationQueue.addOperation(operation)
    }
    
}

extension ReaderViewController {
    
    func handleCardParserWrongTLV() {
        let validationAlert = UIAlertController(title: "Error", message: "Failed to parse data received from the banknote", preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(validationAlert, animated: true, completion: nil)
        
        DispatchQueue.main.async {
            self.hintLabel.text = Constants.hintLabelDefaultText
        }
    }
    
    func handleCardParserLockedCard() {
        print("Card is locked, two first bytes are equal 0x6A86")
        let validationAlert = UIAlertController(title: "Info", message: "This app can’t read protected Tangem banknotes", preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(validationAlert, animated: true, completion: nil)
        
        DispatchQueue.main.async {
            self.hintLabel.text = Constants.hintLabelDefaultText
        }
    }
    
    func handleNonGenuineTangemCard(_ card: Card) {
        let validationAlert = UIAlertController(title: "Error", message: "Not a genuine Tangem card", preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
            UIApplication.navigationManager().showCardDetailsViewControllerWith(cardDetails: card)
        }))
        self.present(validationAlert, animated: true, completion: nil)
        
        DispatchQueue.main.async {
            self.hintLabel.text = Constants.hintLabelDefaultText
        }
    }

}

