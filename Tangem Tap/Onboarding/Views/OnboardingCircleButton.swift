//
//  OnboardingCircleButton.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnboardingCircleButton: View {
    
    enum State {
        case refreshButton, activityIndicator, doneCheckmark
    }
    
    enum Size {
        case `default`, medium, small
        
        var buttonSize: CGSize {
            switch self {
            case .default: return .init(width: 70, height: 70)
            case .medium: return .init(width: 62, height: 62)
            case .small: return .init(width: 45, height: 45)
            }
        }
        
        var buttonFont: Font {
            switch self {
            case .default: return .system(size: 28, weight: .semibold)
            case .medium: return .system(size: 26, weight: .semibold)
            case .small: return .system(size: 20, weight: .semibold)
            }
        }
        
        var checkmarkFont: Font {
            switch self {
            case .default: return .system(size: 24, weight: .bold)
            case .medium: return .system(size: 21, weight: .bold)
            case .small: return .system(size: 15, weight: .bold)
            }
        }
        
        var activityIndicatorStyle: UIActivityIndicatorView.Style {
            switch self {
            case .default, .medium: return .large
            case .small: return .medium
            }
        }
    }
    
    var refreshAction: () -> Void
    var state: State
    var size: Size = .default
    
    private var buttonSize: CGSize { size.buttonSize }
    private var successButtonSize: CGSize {
        .init(width: buttonSize.width * 0.657, height: buttonSize.height * 0.657)
    }
    
    @ViewBuilder
    var backgroundView: some View {
        ZStack {
            Button(action: {
                refreshAction()
            }, label: {
                Circle()
                    .foregroundColor(.clear)
                    .background(
                        Image(systemName: "arrow.clockwise")
                            .font(size.buttonFont)
                            .foregroundColor(state == .refreshButton ? .tangemTapGrayDark6 : .white)
                            .frame(size: buttonSize)
                            .background(Color.white)
                            .cornerRadius(buttonSize.height / 2)
                    )
            })
            .allowsHitTesting(state == .refreshButton)
            ActivityIndicatorView(isAnimating: state == .activityIndicator,
                                  style: size.activityIndicatorStyle,
                                  color: .tangemTapGrayDark6)
                .frame(size: buttonSize)
                .background(Color.white)
                .cornerRadius(buttonSize.height / 2)
                .opacity(state == .activityIndicator ? 1.0 : 0.0)
            Circle()
                .frame(size: buttonSize)
                .foregroundColor(.tangemTapGreen)
                .opacity(0.2)
                .cornerRadius(buttonSize.height / 2)
                .scaleEffect(state == .doneCheckmark ? 1.0 : 0.0001)
            Image(systemName: "checkmark")
                .frame(size: buttonSize)
                .font(size.checkmarkFont)
                .foregroundColor(.white)
                .background(Color.tangemTapGreen
                                .frame(size: successButtonSize)
                                .cornerRadius(successButtonSize.height))
                .cornerRadius(buttonSize.height / 2)
                .scaleEffect(state == .doneCheckmark ? 1.0 : 0.0001)
        }
    }
    
    var body: some View {
        Circle()
            .strokeBorder(style: StrokeStyle(lineWidth: 2))
            .foregroundColor(state == .doneCheckmark ? .tangemTapGreen : .tangemTapGrayLight4)
            .background(backgroundView)
            .frame(size: buttonSize)
    }
}

struct OnboardingCircleButton_Previews: PreviewProvider {
    
    static var previews: some View {
        HStack {
            VStack {
                OnboardingCircleButton(refreshAction: {
                    
                }, state: .refreshButton, size: .default)
                OnboardingCircleButton(refreshAction: {
                    
                }, state: .refreshButton, size: .medium)
                OnboardingCircleButton(refreshAction: {
                    
                }, state: .refreshButton, size: .small)
            }
            
            VStack {
                OnboardingCircleButton(refreshAction: {
                    
                }, state: .activityIndicator, size: .default)
                OnboardingCircleButton(refreshAction: {
                    
                }, state: .activityIndicator, size: .medium)
                OnboardingCircleButton(refreshAction: {
                    
                }, state: .activityIndicator, size: .small)
            }
            
            VStack {
                OnboardingCircleButton(refreshAction: {
                    
                }, state: .doneCheckmark, size: .default)
                OnboardingCircleButton(refreshAction: {
                    
                }, state: .doneCheckmark, size: .medium)
                OnboardingCircleButton(refreshAction: {
                    
                }, state: .doneCheckmark, size: .small)
                
            }
        }
        
    }
    
}
