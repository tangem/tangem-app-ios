//
//  PasteboardService.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit

class PasteboardService {
    
    let lastValue: CurrentValueSubject<String?, Never> = .init(nil)
    private(set) var history: [String] = []
    
    private var subs: AnyCancellable?
    
    init() {
        subs = UIPasteboard.general.publisher(for: \.string)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { newValue in
                self.lastValue.send(newValue)
                guard let value = newValue else {
                    return
                }
                
                self.history.append(value)
            })
    }
    
    func updatePasteboard() {
        let pasteboardVal = UIPasteboard.general.string
        if lastValue.value != pasteboardVal {
            lastValue.send(pasteboardVal)
        }
    }
    
    func clearPasteboard() {
        lastValue.send(nil)
        UIPasteboard.general.string = ""
    }
    
}
