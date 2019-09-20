//
//  ViewController.swift
//  TangemKit_Example
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import TangemKit

class ViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var scanButton: UIButton!
    
    let operationQueue = OperationQueue() 

    var scanNumber = 0

    var session: TangemSession?

    @IBAction func scanButtonPressed(_ sender: Any) {
        session = TangemSession(delegate: self)
        session?.start()
    }
    
    func updateCardWithSubstitutionInfo(card: Card) {
        let operation = CardSubstitutionInfoOperation(card: card) { (card) in
            print(card)
        }
        operationQueue.addOperation(operation)
    }

}

extension ViewController: TangemSessionDelegate {

    func tangemSessionDidRead(card: Card) {
        if scanNumber == 0 {
            textView.text = ""
        }
        textView.text.append("Scan \(scanNumber)\(card.debugDescription())\n\n")
        scanNumber += 1
        
        if scanNumber % 2 == 0 {
            updateCardWithSubstitutionInfo(card: card)
        }
    }

    func tangemSessionDidFailWith(error: TangemSessionError) {
        print("Error: " + error.localizedDescription)
    }

}

extension Card {

    func debugDescription() -> String {

        return [cardID, challenge!].reduce(into: "", { (next, string) in
            next += "\n" + string
        })

    }

}

