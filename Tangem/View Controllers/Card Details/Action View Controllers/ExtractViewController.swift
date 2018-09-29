//
//  ExtractViewController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation

class ExtractViewController: ModalActionViewController {
    
    @IBOutlet weak var contentLabel: UILabel!
    
    var contentText = "Value extraction is not available on the iPhone at this time"
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let paragraphStyle = paragraphStyleWith(lineSpacingChange: 8.0, alignment: .center)
        let attributedText = NSAttributedString(string: contentText, attributes: [NSAttributedStringKey.paragraphStyle : paragraphStyle,
                                                                                  NSAttributedStringKey.kern : 1.12])
        
        contentLabel.attributedText = attributedText
    }
    
    private func paragraphStyleWith(lineSpacingChange: CGFloat, alignment: NSTextAlignment = .center) -> NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing += lineSpacingChange
        paragraphStyle.alignment = alignment
        
        return paragraphStyle
    }
    
}
