//
//  SessionViewDelegate.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import CoreHaptics

/// Allows interaction with users and shows visual elements.
/// Its default implementation, `DefaultSessionViewDelegate`, is in our SDK.
public protocol SessionViewDelegate: class {
    func showAlertMessage(_ text: String)
    
    /// It is called when security delay is triggered by the card. A user is expected to hold the card until the security delay is over.
    func showSecurityDelay(remainingMilliseconds: Int)
    
    /// It is called when a user is expected to enter pin code.
    func requestPin(completion: @escaping () -> Result<String, Error>)
    
    /// It is called when tag was found
    func tagConnected()
    
    /// It is called when tag was lost
    func tagLost()
    
    func wrongCard(message: String?)
    
    func sessionStarted()
    
    func sessionStopped()
    
    func sessionInitialized()
}

@available(iOS 13.0, *)
final class DefaultSessionViewDelegate: SessionViewDelegate {
    private let reader: CardReader
    private var engine: CHHapticEngine?
    private var engineNeedsStart = true
    
    private lazy var delayFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = .second
        return formatter
    }()
    
    private lazy var supportsHaptics: Bool = {
        return CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }()
    
    private lazy var bundle: Bundle = {
         let selfBundle = Bundle(for: DefaultSessionViewDelegate.self)
         if let path = selfBundle.path(forResource: "TangemSdk", ofType: "bundle"), //for pods
             let bundle = Bundle(path: path) {
             return bundle
         } else {
             return selfBundle
         }
     }()
    
    init(reader: CardReader) {
        self.reader = reader
        createHapticEngine()
    }
    
    func showAlertMessage(_ text: String) {
        reader.alertMessage = text
    }
    
    func showSecurityDelay(remainingMilliseconds: Int) {
        if let timeString = delayFormatter.string(from: TimeInterval(remainingMilliseconds/100)) {
            playTick()
            showAlertMessage(Localization.secondsLeft(timeString))
        }
    }
    
    func requestPin(completion: @escaping () -> Result<String, Error>) {
        //[REDACTED_TODO_COMMENT]
    }
    
    func tagConnected() {
        print("tag did connect")
    }
    
    func tagLost() {
        print("tag lost")
    }
    
    func wrongCard(message: String?) {
        playError()
        
        if let message = message {
            let oldMessage = reader.alertMessage
            showAlertMessage(message)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.showAlertMessage(oldMessage)
            }
        }
    }
    
    func sessionStarted() {
        startHapticsEngine()
    }
    
    func sessionInitialized() {
        playSuccess()
    }
    
    func sessionStopped() {
        stopHapticsEngine()
    }
    
    private func playSuccess() {
        if supportsHaptics {
            do {
                
                guard let path = bundle.path(forResource: "Success", ofType: "ahap") else {
                  return
              }
                             
              try engine?.playPattern(from: URL(fileURLWithPath: path))
            } catch let error {
                print("Error creating a haptic transient pattern: \(error)")
            }
        }
    }
    
    private func playError() {
        if supportsHaptics {
            do {
                guard let path = bundle.path(forResource: "Error", ofType: "ahap") else {
                    return
                }
                               
                try engine?.playPattern(from: URL(fileURLWithPath: path))
            } catch let error {
                print("Error creating a haptic transient pattern: \(error)")
            }
        } else {
            let notificationGenerator = UINotificationFeedbackGenerator()
            notificationGenerator.notificationOccurred(.error)
        }
    }
    
    private func playTick() {
        if supportsHaptics {
            do {
                // Create an event (static) parameter to represent the haptic's intensity.
                let intensityParameter = CHHapticEventParameter(parameterID: .hapticIntensity,
                                                                value: 0.75)
                
                // Create an event (static) parameter to represent the haptic's sharpness.
                let sharpnessParameter = CHHapticEventParameter(parameterID: .hapticSharpness,
                                                                value: 0.5)
                
                // Create an event to represent the transient haptic pattern.
                let event = CHHapticEvent(eventType: .hapticTransient,
                                          parameters: [intensityParameter, sharpnessParameter],
                                          relativeTime: 0)
                
                let pattern = try CHHapticPattern(events: [event], parameters: [])
                
                // Create a player to play the haptic pattern.
                let player = try engine?.makePlayer(with: pattern)
                try player?.start(atTime: CHHapticTimeImmediate) // Play now.
            } catch let error {
                print("Error creating a haptic transient pattern: \(error)")
            }
        } else {
            let generator = UIImpactFeedbackGenerator(style: UIImpactFeedbackGenerator.FeedbackStyle.light)
            generator.impactOccurred()
        }
    }
    
    private func stopHapticsEngine() {
        guard supportsHaptics else {
            return
        }
        
        engine?.stop(completionHandler: {[weak self] error in
            if let error = error {
                print("Haptic Engine Shutdown Error: \(error)")
                return
            }
            self?.engineNeedsStart = true
        })
    }
    
    private func startHapticsEngine() {
        guard supportsHaptics && engineNeedsStart else {
            return
        }
        
        engine?.start(completionHandler: {[weak self] error in
            if let error = error {
                print("Haptic Engine Start Error: \(error)")
                return
            }
            self?.engineNeedsStart = false
        })
    }
    
    private func createHapticEngine() {
        guard supportsHaptics else {
            return
        }
        
        do {
            engine = try CHHapticEngine()
            engine!.playsHapticsOnly = true
            engine!.stoppedHandler = {[weak self] reason in
                print("CHHapticEngine stop handler: The engine stopped for reason: \(reason.rawValue)")
                self?.engineNeedsStart = true
            }
            engine!.resetHandler = {[weak self] in
                print("Reset Handler: Restarting the engine.")
                do {
                    // Try restarting the engine.
                    try self?.engine?.start()
                    
                    // Indicate that the next time the app requires a haptic, the app doesn't need to call engine.start().
                    self?.engineNeedsStart = false
                    
                } catch {
                    print("Failed to start the engine")
                }
            }
        } catch {
            print("CHHapticEngine error: \(error)")
        }
    }
}
