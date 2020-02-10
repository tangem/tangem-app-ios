//
//  TangemTimer.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

class TangemTimer {
    private var timer: Timer?
    private let completion: () -> Void
    private let timeInterval: TimeInterval
    
    init(timeInterval: TimeInterval, completion: @escaping () -> Void) {
        self.timeInterval = timeInterval
        self.completion = completion
    }
    
    func start() {
        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.timer = Timer(timeInterval: self.timeInterval, repeats: false, block: {[weak self] timer in
                self?.completion()
            })
            self.timer!.tolerance = 0.1 * self.timeInterval
            RunLoop.main.add(self.timer!, forMode: RunLoop.Mode.common)
        }
    }
    
    func stop() {
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
