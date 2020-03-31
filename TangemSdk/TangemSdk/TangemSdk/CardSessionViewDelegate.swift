//
//  CardSessionViewDelegate.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

/// Allows interaction with users and shows visual elements.
/// Its default implementation, `DefaultCardSessionViewDelegate`, is in our  module.
public protocol CardSessionViewDelegate: class {
    func showAlertMessage(_ text: String)
    
    /// It is called when security delay is triggered by the card. A user is expected to hold the card until the security delay is over.
    func showSecurityDelay(remainingMilliseconds: Int)
    
    /// It is called when a user is expected to enter pin code.
    func requestPin(completion: @escaping () -> Result<String, Error>)
    
     /// It is called when tag was found
    func tagDidConnect()
}

final class DefaultCardSessionViewDelegate: CardSessionViewDelegate {
    private let reader: CardReader
    
    private lazy var delayFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = .second
        return formatter
    }()
    
    init(reader: CardReader) {
        self.reader = reader
    }
    
    func showAlertMessage(_ text: String) {
        reader.alertMessage = text
    }
    
    func showSecurityDelay(remainingMilliseconds: Int) {
        if let timeString = delayFormatter.string(from: TimeInterval(remainingMilliseconds/100)) {
            let generator = UIImpactFeedbackGenerator(style: UIImpactFeedbackGenerator.FeedbackStyle.light)
            generator.impactOccurred()
            showAlertMessage(Localization.secondsLeft(timeString))
        }
    }
    
    func requestPin(completion: @escaping () -> Result<String, Error>) {
        //[REDACTED_TODO_COMMENT]
    }
    
    func tagDidConnect() {
        print("tag did connect")
    }
}
