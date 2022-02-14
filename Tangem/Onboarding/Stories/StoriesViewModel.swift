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
    private var timerSubscription: AnyCancellable?
    
    private let fps: Double = 60
    private let storyDuration: Double
    private let restartAutomatically = true
    
    init(numberOfViews: Int, storyDuration: Double) {
        self.numberOfViews = numberOfViews
        self.storyDuration = storyDuration
    }
    
    func onAppear() {
        DispatchQueue.main.async {
            self.restartTimer()
        }
    }
    
    func move(forward: Bool) {
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

        withAnimation(.linear(duration: storyDuration)) {
            currentProgress = 1
        }
        
        timerSubscription = Timer.publish(every: storyDuration, on: .main, in: .default).autoconnect()
            .sink { [weak self] _ in
                self?.move(forward: true)
            }
    }
}
