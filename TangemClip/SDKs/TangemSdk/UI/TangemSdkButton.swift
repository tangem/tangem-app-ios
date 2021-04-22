//
//  TangemSdkButton.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import UIKit

class TangemSdkButton: UIButton {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        layer.cornerRadius = 8
    }
    
    override public var isEnabled: Bool {
        didSet {
            UIView.animate(withDuration: 0.2) {
                self.backgroundColor = self.isEnabled ? .deepSkyBlue : .systemGray
            }
        }
    }
}
