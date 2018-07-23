//
//  ViewController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Yulia Moskaleva. All rights reserved.
//

import UIKit

class ReaderViewController: UIViewController {
    
    var cardList = [Card]()
    let helper = NFCHelper()
    
    lazy var cardParser: CardParser = {
       return CardParser(delegate: self)
    }()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.barTintColor = UIColor(red:0.0074375583790242672, green: 0.24186742305755615, blue: 0.4968341588973999, alpha: 1)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        helper.onNFCResult = onNFCResult(success:msg:)
        helper.restartSession()
    }
    
    @IBAction func readNFC(_ sender: Any) {
        helper.onNFCResult = onNFCResult(success:msg:)
        helper.restartSession()
        
        #if targetEnvironment(simulator)
//            self.cardParser.parse(payload: TestData.seed.rawValue)
            self.cardParser.parse(payload: TestData.seed.rawValue)
//            self.cardParser.parse(payload: TestData.ert.rawValue)
        #endif
    }
    
    func onNFCResult(success: Bool, msg: String) {
        DispatchQueue.main.async {
            guard success else {
                print("\(msg)")
                return
            }
            
            self.cardParser.parse(payload: msg)
        }
    }

    func showCardDetailsWith(card: Card) {
        let storyBoard = UIStoryboard(name: "Card", bundle: nil)
        guard let nextViewController = storyBoard.instantiateViewController(withIdentifier: "CardViewController") as? CardViewController else {
            return
        }
        
        nextViewController.cardDetails = card
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }

}

extension ReaderViewController: CardParserDelegate {
    
    func cardParserWrongTLV(_ parser: CardParser) {
        let validationAlert = UIAlertController(title: "Failed to parse data received from the banknote", message: "", preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(validationAlert, animated: true, completion: nil)
    }
    
    func cardParserLockedCard(_ parser: CardParser) {
        print("Card is locked, two first bytes are equel 0x6A86")
        let validationAlert = UIAlertController(title: "This app can’t read protected Tangem banknotes", message: "", preferredStyle: .alert)
        validationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(validationAlert, animated: true, completion: nil)
    }
    
    func cardParser(_ parser: CardParser, didFinishWith card: Card) {
        self.showCardDetailsWith(card: card)
    }
}

