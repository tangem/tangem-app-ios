//
//  ViewController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Yulia Moskaleva. All rights reserved.
//

import UIKit

class ReaderViewController: UIViewController {

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
    let cardParser = CardParser()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.cardParser.delegate = self
        self.helper.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        gradientView.layer.sublayers?.forEach({ $0.frame = gradientView.bounds })
    }

    func showCardDetailsWith(card: Card) {
        let storyBoard = UIStoryboard(name: "Card", bundle: nil)
        guard let nextViewController = storyBoard.instantiateViewController(withIdentifier: "CardDetailsViewController") as? CardDetailsViewController else {
            return
        }
        
        nextViewController.cardDetails = card
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
    
    // MARK: Actions
    
    @IBAction func scanButtonPressed(_ sender: Any) {
        #if targetEnvironment(simulator)
        self.showSimulationSheet()
        #else
        self.helper.restartSession()
        #endif
    }
    
    func showSimulationSheet() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let btcAction = UIAlertAction(title: "BTC", style: .default) { (_) in
            self.cardParser.parse(payload: TestData.btcWallet.rawValue)
        }
        let seedAction = UIAlertAction(title: "SEED", style: .default) { (_) in
            self.cardParser.parse(payload: TestData.seed.rawValue)
        }
        let ethAction = UIAlertAction(title: "ETH", style: .default) { (_) in
            self.cardParser.parse(payload: TestData.ethWallet.rawValue)
        }
        let ertAction = UIAlertAction(title: "ERT", style: .default) { (_) in
            self.cardParser.parse(payload: TestData.ert.rawValue)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(btcAction)
        alertController.addAction(seedAction)
        alertController.addAction(ethAction)
        alertController.addAction(ertAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func techButtonPressed(_ sender: Any) {
        
    }
    
}

extension ReaderViewController: NFCHelperDelegate {
    
    func nfcHelper(_ helper: NFCHelper, didInvalidateWith error: Error) {
        print("\(error.localizedDescription)")
    }
    
    func nfcHelper(_ helper: NFCHelper, didDetectCardWith hexPayload: String) {
        DispatchQueue.main.async {
            self.cardParser.parse(payload: hexPayload)
        }
    }
    
}

extension ReaderViewController: CardParserDelegate {
    
    func cardParserWrongTLV(_ parser: CardParser) {
        let validationAlert = UIAlertController(title: "Error", message: "Failed to parse data received from the banknote", preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(validationAlert, animated: true, completion: nil)
    }
    
    func cardParserLockedCard(_ parser: CardParser) {
        print("Card is locked, two first bytes are equal 0x6A86")
        let validationAlert = UIAlertController(title: "Info", message: "This app can’t read protected Tangem banknotes", preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(validationAlert, animated: true, completion: nil)
    }
    
    func cardParser(_ parser: CardParser, didFinishWith card: Card) {
        self.showCardDetailsWith(card: card)
    }
}

