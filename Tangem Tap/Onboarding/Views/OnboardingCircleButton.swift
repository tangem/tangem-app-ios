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
            case .default: return .init(width: 68, height: 68)
            case .medium: return .init(width: 60, height: 60)
            case .small: return .init(width: 44, height: 44)
            }
        }
        
        var activityIndicatorStyle: UIActivityIndicatorView.Style {
            switch self {
            case .default: return .large
            case .medium, .small: return .medium
            }
        }
        
        var refreshImageSize: CGSize {
            switch self {
            case .default: return .init(width: 30, height: 30)
            case .medium: return .init(width: 26, height: 26)
            case .small: return .init(width: 18, height: 18)
            }
        }
        
        var checkmarkSize: CGSize {
            switch self {
            case .default: return .init(width: 18, height: 18)
            case .medium: return .init(width: 15, height: 15)
            case .small: return .init(width: 12, height: 12)
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
                    .foregroundColor(.white)
                    .overlay(
                        Image("refresh")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(state == .refreshButton ? .tangemTapGrayDark6 : .white)
                            .frame(size: size.refreshImageSize)
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
            Color.tangemTapGreen
                .frame(size: successButtonSize)
                .cornerRadius(successButtonSize.height)
                .overlay(
                    Image("design.checkmark")
                        .resizable()
                        .frame(size: size.checkmarkSize)
                        .cornerRadius(buttonSize.height / 2)
                )
                .scaleEffect(state == .doneCheckmark ? 1.0 : 0.0001)
        }
    }
    
    var body: some View {
        Circle()
            .strokeBorder(style: StrokeStyle(lineWidth: 1))
            .foregroundColor(state == .doneCheckmark ? .tangemTapGreen : .tangemTapGrayLight4)
            .background(backgroundView)
            .frame(size: buttonSize)
    }
}

struct OnboardingCircleButton_Previews: PreviewProvider {
    
    static var previews: some View {
        Color.yellow
            .overlay(
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
            )
    }
    
}
