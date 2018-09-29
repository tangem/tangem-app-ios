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

    @IBOutlet weak var techImageView: UIImageView! {
        didSet {
            techImageView.layer.cornerRadius = techImageView.frame.width / 2.0
        }
    }
    
    @IBOutlet weak var scanImageView: UIImageView! {
        didSet {
            scanImageView.layer.cornerRadius = scanImageView.frame.width / 2.0
        }
    }
    
    @IBOutlet weak var scanLabel: UILabel! {
        didSet {
            scanLabel.font = UIFont.tgm_maaxFontWith(size: 16.0, weight: .medium)
        }
    }
    
    @IBOutlet weak var techLabel: UILabel! {
        didSet {
            techLabel.font = UIFont.tgm_maaxFontWith(size: 16.0, weight: .medium)
        }
    }
    
    @IBOutlet weak var gradientView: UIView! {
        didSet {
            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = gradientView.frame
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 1)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 0)
            gradientLayer.colors = [UIColor.black.cgColor, UIColor.clear.cgColor]
            
            gradientView.layer.addSublayer(gradientLayer)
        }
    }
    
    let helper = NFCHelper()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.helper.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        gradientView.layer.sublayers?.forEach({ $0.frame = gradientView.bounds })
    }
    
    // MARK: Actions
    
    @IBAction func scanButtonPressed(_ sender: Any) {
        #if targetEnvironment(simulator)
        self.showSimulationSheet()
        #else
        self.helper.restartSession()
        #endif
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
    
    func launchParsingOperationWith(payload: Data) {
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

extension ReaderViewController: NFCHelperDelegate {
    
    func nfcHelper(_ helper: NFCHelper, didInvalidateWith error: Error) {
        print("\(error.localizedDescription)")
    }
    
    func nfcHelper(_ helper: NFCHelper, didDetectCardWith payload: Data) {
        launchParsingOperationWith(payload: payload)
    }
    
}

extension ReaderViewController {
    
    func handleCardParserWrongTLV() {
        let validationAlert = UIAlertController(title: "Error", message: "Failed to parse data received from the banknote", preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(validationAlert, animated: true, completion: nil)
    }
    
    func handleCardParserLockedCard() {
        print("Card is locked, two first bytes are equal 0x6A86")
        let validationAlert = UIAlertController(title: "Info", message: "This app can’t read protected Tangem banknotes", preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(validationAlert, animated: true, completion: nil)
    }

}

