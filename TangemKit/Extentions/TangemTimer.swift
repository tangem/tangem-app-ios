//
//  Timer+.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

class TangemTimer {
    var timer: Timer?
    let completionHandler: () -> Void
    let timeInterval: TimeInterval
    
    init(timeInterval: TimeInterval, completionHandler: @escaping () -> Void) {
        self.timeInterval = timeInterval
        self.completionHandler = completionHandler
    }
    
    func start() {
        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.timer = Timer(timeInterval: self.timeInterval, repeats: false, block: {[weak self] timer in
                self?.completionHandler()
            })
            self.timer!.tolerance = 0.1 * self.timeInterval
            RunLoop.main.add(self.timer!, forMode: .commonModes)
        }
    }
    
    func stop() {
        guard let timer = timer, timer.isValid else {
            return
        }
        
        DispatchQueue.main.async {
            self.timer?.invalidate()
        }
    }
    
    static func stopTimers(_ timers: [TangemTimer]) {
        DispatchQueue.main.async {
            for timer in timers {
                timer.timer?.invalidate()
            }
        }
    }
}
