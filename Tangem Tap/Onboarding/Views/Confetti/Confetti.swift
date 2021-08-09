//
//  ConfettiType.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

private var confettiTypes: [ConfettiType] = {
    let confettiColors = [
        #colorLiteral(red: 149.0 / 255.0,green: 58.0 / 255.0,blue: 255.0 / 255.0,alpha: 1.0), #colorLiteral(red:255.0 / 255.0,green:195.0 / 255.0,blue:41.0 / 255.0,alpha: 1.0), #colorLiteral(red:255.0 / 255.0,green:101.0 / 255.0,blue:26.0 / 255.0,alpha: 1.0),
        #colorLiteral(red:123.0 / 255.0,green:92.0 / 255.0,blue:255.0 / 255.0,alpha: 1.0), #colorLiteral(red:76.0 / 255.0,green:126.0 / 255.0,blue:255.0 / 255.0,alpha: 1.0), #colorLiteral(red:71.0 / 255.0,green:192.0 / 255.0,blue:255.0 / 255.0,alpha: 1.0),
        #colorLiteral(red:255.0 / 255.0,green:47.0 / 255.0,blue:39.0 / 255.0,alpha: 1.0), #colorLiteral(red:255.0 / 255.0,green:91.0 / 255.0,blue:134.0 / 255.0,alpha: 1.0), #colorLiteral(red:233.0 / 255.0,green:122.0 / 255.0,blue:208.0 / 255.0,alpha: 1.0)
    ]
    
    return [ConfettiPosition.foreground, ConfettiPosition.background].flatMap { position in
        return [ConfettiShape.rectangle, ConfettiShape.circle].flatMap { shape in
            return confettiColors.map { color in
                return ConfettiType(color: color, shape: shape, position: position)
            }
        }
    }
}()

struct ConfettiView: UIViewRepresentable {
    var shouldFireConfetti: Binding<Bool>
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.frame = UIScreen.main.bounds
        view.isUserInteractionEnabled = false
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if shouldFireConfetti.wrappedValue {
            launchConfetti(for: uiView)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.shouldFireConfetti.wrappedValue = false
            }
            
        }
    }
    
    
    
    private func foregroundConfettiLayer(for view: UIView) -> CAEmitterLayer { createConfettiLayer(for: view) }
    
    private func backgroundConfettiLayer(for view: UIView) -> CAEmitterLayer {
        let emitterLayer = createConfettiLayer(for: view)
        
        for emitterCell in emitterLayer.emitterCells ?? [] {
            emitterCell.scale = 0.5
        }
        
        emitterLayer.opacity = 0.5
        emitterLayer.speed = 0.95
        
        return emitterLayer
    }
    
    private func launchConfetti(for view: UIView) {
        view.layer.sublayers?.removeAll()
        for layer in [foregroundConfettiLayer(for: view), backgroundConfettiLayer(for: view)] {
            view.layer.addSublayer(layer)
            layer.frame = view.bounds
            addBehaviors(to: layer)
            addAnimations(to: layer)
        }
    }
    
    
    func createConfettiCells() -> [CAEmitterCell] {
        return confettiTypes.map { confettiType in
            let cell = CAEmitterCell()
            cell.name = confettiType.name
            
            cell.beginTime = 0.1
            cell.birthRate = 100
            cell.contents = confettiType.image.cgImage
            cell.emissionRange = CGFloat(Double.pi)
            cell.lifetime = 3.5
            cell.spin = 4
            cell.spinRange = 8
            cell.velocityRange = 0
            cell.yAcceleration = 0
            
            cell.setValue("plane", forKey: "particleType")
            cell.setValue(Double.pi, forKey: "orientationRange")
            cell.setValue(Double.pi / 2, forKey: "orientationLongitude")
            cell.setValue(Double.pi / 2, forKey: "orientationLatitude")
            
            return cell
        }
    }

    func createBehavior(type: String) -> NSObject {
        let behaviorClass = NSClassFromString("CAEmitterBehavior") as! NSObject.Type
        let behaviorWithType = behaviorClass.method(for: NSSelectorFromString("behaviorWithType:"))!
        let castedBehaviorWithType = unsafeBitCast(behaviorWithType, to:(@convention(c)(Any?, Selector, Any?) -> NSObject).self)
        return castedBehaviorWithType(behaviorClass, NSSelectorFromString("behaviorWithType:"), type)
    }

    func horizontalWaveBehavior() -> Any {
        let behavior = createBehavior(type: "wave")
        behavior.setValue([100, 0, 0], forKeyPath: "force")
        behavior.setValue(0.5, forKeyPath: "frequency")
        return behavior
    }

    func verticalWaveBehavior() -> Any {
        let behavior = createBehavior(type: "wave")
        behavior.setValue([0, 100, 0], forKeyPath: "force")
        behavior.setValue(3, forKeyPath: "frequency")
        return behavior
    }


    func attractorBehavior(for emitterLayer: CAEmitterLayer) -> Any {
        let behavior = createBehavior(type: "attractor")
        behavior.setValue("attractor", forKeyPath: "name")
        
        behavior.setValue(-150, forKeyPath: "falloff")
        behavior.setValue(150, forKeyPath: "radius")
        behavior.setValue(0, forKeyPath: "stiffness")
        
        behavior.setValue(CGPoint(x: emitterLayer.emitterPosition.x,
                                  y: emitterLayer.emitterPosition.y + 20),
                          forKeyPath: "position")
        behavior.setValue(-50, forKeyPath: "zPosition")
        
        return behavior
    }

    func addBehaviors(to layer: CAEmitterLayer) {
        layer.setValue([
            horizontalWaveBehavior(),
            verticalWaveBehavior(),
            attractorBehavior(for: layer)
        ], forKey: "emitterBehaviors")
    }

    func addAttractorAnimation(to layer: CALayer) {
        let animation = CAKeyframeAnimation()
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animation.duration = 3
        animation.keyTimes = [0, 0.4]
        animation.values = [80, 5]
        
        layer.add(animation, forKey: "emitterBehaviors.attractor.stiffness")
    }

    func addBirthrateAnimation(to layer: CALayer) {
        let animation = CABasicAnimation()
        animation.duration = 1
        animation.fromValue = 1
        animation.toValue = 0
        
        layer.add(animation, forKey: "birthRate")
    }

    func addAnimations(to layer: CAEmitterLayer) {
        addAttractorAnimation(to: layer)
        addBirthrateAnimation(to: layer)
        addDragAnimation(to: layer)
        addGravityAnimation(to: layer)
    }

    func dragBehavior() -> Any {
        let behavior = createBehavior(type: "drag")
        behavior.setValue("drag", forKey: "name")
        behavior.setValue(2, forKey: "drag")
        
        return behavior
    }

    func addDragAnimation(to layer: CALayer) {
        let animation = CABasicAnimation()
        animation.duration = 0.65
        animation.fromValue = 0
        animation.toValue = 2
        
        layer.add(animation, forKey:  "emitterBehaviors.drag.drag")
    }

    func addGravityAnimation(to layer: CALayer) {
        let animation = CAKeyframeAnimation()
        animation.duration = 6
        animation.keyTimes = [0.05, 0.1, 0.5, 1]
        animation.values = [0, 100, 2000, 3000]
        
        for image in confettiTypes {
            layer.add(animation, forKey: "emitterCells.\(image.name).yAcceleration")
        }
    }

    func createConfettiLayer(for view: UIView) -> CAEmitterLayer {
        let emitterLayer = CAEmitterLayer()
        
        emitterLayer.birthRate = 0
        emitterLayer.emitterCells = createConfettiCells()
        emitterLayer.emitterPosition = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.minY - 150)
        emitterLayer.emitterSize = CGSize(width: 100, height: 120)
        emitterLayer.emitterShape = .sphere
        emitterLayer.frame = UIScreen.main.bounds
        
        emitterLayer.beginTime = CACurrentMediaTime()
        return emitterLayer
    }
  
}
