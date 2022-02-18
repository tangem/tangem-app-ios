//
//  StoriesViewModel.swift
//  StoriesDemo
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import Combine
import SwiftUI

class StoriesViewModel: ObservableObject {
    @Published var selection = 0
    @Published var currentProgress = 0.0
    let numberOfViews: Int
    let highFpsViews: [Int]
    
    private var timerSubscription: AnyCancellable?
    private var longTapTimerSubscription: AnyCancellable?
    private var longTapDetected = false
    private var currentDragLocation: CGPoint?
    
    private let highFps: Double = 60
    private let lowFps: Double = 12
    
    private let storyDuration: Double
    private let restartAutomatically = true
    private let longTapDuration = 0.5
    private let minimumSwipeDistance = 50.0
    
    init(numberOfViews: Int, highFpsViews: [Int], storyDuration: Double) {
        self.numberOfViews = numberOfViews
        self.highFpsViews = highFpsViews
        self.storyDuration = storyDuration
    }
    
    func onAppear() {
        restartTimer()
    }
    
    func onDisappear() {
        pauseTimer()
    }
    
    func didDrag(_ current: CGPoint) {
        if longTapDetected {
            return
        }
        
        if let currentDragLocation = currentDragLocation, currentDragLocation.distance(to: current) < minimumSwipeDistance {
            return
        }

        currentDragLocation = current
        pauseTimer()
        
        longTapTimerSubscription = Timer.publish(every: longTapDuration, on: RunLoop.main, in: .default)
            .autoconnect()
            .sink { [unowned self] _ in
                self.currentDragLocation = nil
                self.longTapTimerSubscription = nil
                self.longTapDetected = true
            }
    }
    
    func didEndDrag(_ current: CGPoint, destination: CGPoint, viewWidth: CGFloat) {
        if let currentDragLocation = currentDragLocation {
            let distance = (destination.x - current.x)
            
            let moveForward: Bool
            if abs(distance) < minimumSwipeDistance {
                moveForward = currentDragLocation.x > viewWidth / 2
            } else {
                moveForward = distance > 0
            }

            move(forward: moveForward)
        } else {
            resumeTimer()
        }
        
        currentDragLocation = nil
        longTapTimerSubscription = nil
        longTapDetected = false
    }
    
    private func move(forward: Bool) {
        let newIndex = max(0, selection + (forward ? 1 : -1))
        if newIndex < numberOfViews {
            selection = newIndex
            restartTimer()
        } else if restartAutomatically {
            selection = 0
            restartTimer()
        }
    }
    
    private func restartTimer() {
        currentProgress = 0
        resumeTimer()
    }
    
    private func pauseTimer() {
        timerSubscription = nil
    }
    
    private func resumeTimer() {
        let fps = highFpsViews.contains(selection) ? highFps : lowFps
        timerSubscription = Timer.publish(every: 1 / fps, on: .main, in: .default)
            .autoconnect()
            .sink { [unowned self] _ in
                if self.currentProgress >= 1 {
                    self.move(forward: true)
                } else {
                    self.currentProgress += 1 / fps / self.storyDuration
                }
            }
    }
}


fileprivate extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        return sqrt(pow(self.x - other.x, 2) + pow(self.y - other.y, 2))
    }
}
