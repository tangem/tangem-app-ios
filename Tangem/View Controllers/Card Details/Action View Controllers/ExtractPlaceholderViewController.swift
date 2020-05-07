//
//  ExtractPlaceholderViewController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import UIKit

class ExtractPlaceholderViewController: UIViewController {
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel! {
           didSet {
            titleLabel.text = Localizations.loadedWalletBtnExtract.uppercased()
           }
       }
    
    var contentText: String = ""
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
 
        let paragraphStyle = paragraphStyleWith(lineSpacingChange: 8.0, alignment: .center)
        let attributedText = NSAttributedString(string: contentText, attributes: [NSAttributedString.Key.paragraphStyle : paragraphStyle,
                                                                                  NSAttributedString.Key.kern : 1.12])
        
        contentLabel.attributedText = attributedText
    }
    
    private func paragraphStyleWith(lineSpacingChange: CGFloat, alignment: NSTextAlignment = .center) -> NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing += lineSpacingChange
        paragraphStyle.alignment = alignment
        
        return paragraphStyle
    }
}
