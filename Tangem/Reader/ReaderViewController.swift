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
    
    @IBAction func readNFC(_ sender: Any) {
        
        
        #if targetEnvironment(simulator)
//            self.cardParser.parse(payload: TestData.seed.rawValue)
            self.cardParser.parse(payload: TestData.seed.rawValue)
//            self.cardParser.parse(payload: TestData.ert.rawValue)
        #endif
    }
    
    func onNFCResult(success: Bool, msg: String) {
        
    }

    func showCardDetailsWith(card: Card) {
        let storyBoard = UIStoryboard(name: "Card", bundle: nil)
        guard let nextViewController = storyBoard.instantiateViewController(withIdentifier: "CardViewController") as? CardViewController else {
            return
        }
        
        nextViewController.cardDetails = card
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
    
    // MARK: Actions
    
    @IBAction func scanButtonPressed(_ sender: Any) {
        self.helper.restartSession()
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

