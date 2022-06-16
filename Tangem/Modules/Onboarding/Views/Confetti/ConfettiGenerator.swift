//
//  ConfettiGenerator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import UIKit

enum ConfettiGeneratorPosition {
    case aboveTop, bottom, custom(point: CGPoint)
    
    var position: CGPoint {
        let screenBounds = UIScreen.main.bounds
        switch self {
        case .aboveTop: return CGPoint(x: screenBounds.midX, y: screenBounds.minY - 150)
        case .bottom: return CGPoint(x: screenBounds.midX, y: screenBounds.maxY + 20)
        case .custom(let point): return point
        }
    }
}

struct ConfettiGeneratorSettings {
    let generatorPosition: ConfettiGeneratorPosition
    let generatorSize: CGSize
    let confettiLifetime: Float
    let generationDuration: Double
    
    static func defaultSettings(at position: ConfettiGeneratorPosition = .aboveTop) -> ConfettiGeneratorSettings {
        ConfettiGeneratorSettings(
            generatorPosition: position,
            generatorSize: CGSize(width: 100, height: 120),
            confettiLifetime: 3.5,
            generationDuration: 1
        )
    }
}

class ConfettiGenerator {
    
    static let shared = ConfettiGenerator()
    
    private let defaultColors: [UIColor] = [
        #colorLiteral(red: 1, green: 0.3615367413, blue: 0.5344620347, alpha: 1), #colorLiteral(red: 0.3234148026, green: 0.5075122118, blue: 1, alpha: 1), #colorLiteral(red: 0.9215686275, green: 0.2705882353, blue: 0.231372549, alpha: 1), #colorLiteral(red: 0.9568627451, green: 0.768627451, blue: 0.2823529412, alpha: 1), #colorLiteral(red: 0.4196078431, green: 0.7450980392, blue: 0.9764705882, alpha: 1), #colorLiteral(red: 0.537254902, green: 0.1607843137, blue: 0.9254901961, alpha: 1), #colorLiteral(red: 0.999055922, green: 0.3810364008, blue: 0.0866015926, alpha: 1)
    ]
    private var confettiTypes: [ConfettiType] = []
    
    private init() {
        confettiTypes = generateConfettiTypes(with: defaultColors)
    }
    
    func generateConfettiLayers(with settings: ConfettiGeneratorSettings) -> [CALayer] {
        var layers: [CALayer] = []
        let confettiLayers = [
            foregroundConfettiLayer(emitterPosition: settings.generatorPosition.position, emitterSize: settings.generatorSize, confettiLifetime: settings.confettiLifetime),
            backgroundConfettiLayer(emitterPosition: settings.generatorPosition.position, emitterSize: settings.generatorSize, confettiLifetime: settings.confettiLifetime, scale: 0.6, opacity: 0.9, speed: 0.95),
            backgroundConfettiLayer(emitterPosition: settings.generatorPosition.position, emitterSize: settings.generatorSize, confettiLifetime: settings.confettiLifetime, scale: 0.35, opacity: 0.8, speed: 0.9)
        ]
        for layer in confettiLayers {
            addBehaviors(to: layer)
            addAnimations(to: layer, generationDuration: settings.generationDuration, confettiLifetime: settings.confettiLifetime)
            layers.append(layer)
        }
        return layers
    }
    
    private func generateConfettiTypes(with colors: [UIColor]) -> [ConfettiType] {
        [ConfettiPosition.foreground, ConfettiPosition.background].flatMap { position in
            [ConfettiShape.rectangle, ConfettiShape.circle, .triangle].flatMap { shape in
                colors.map { color in
                    ConfettiType(color: color, shape: shape, position: position)
                }
            }
        }
    }

    private func foregroundConfettiLayer(emitterPosition: CGPoint, emitterSize: CGSize, confettiLifetime: Float) -> CAEmitterLayer {
        createConfettiLayer(emitterPosition: emitterPosition, emitterSize: emitterSize, confettiLifetime: confettiLifetime)
    }
    
    private func backgroundConfettiLayer(emitterPosition: CGPoint, emitterSize: CGSize, confettiLifetime: Float, scale: CGFloat = 0.5, opacity: Float = 0.8, speed: Float = 0.95) -> CAEmitterLayer {
        let emitterLayer = createConfettiLayer(emitterPosition: emitterPosition, emitterSize: emitterSize, confettiLifetime: confettiLifetime)
        
        for emitterCell in emitterLayer.emitterCells ?? [] {
            emitterCell.scale = scale
        }
        
        emitterLayer.opacity = opacity
        emitterLayer.speed = speed
        
        return emitterLayer
    }
    private func createConfettiCells(confettiLifetime: Float) -> [CAEmitterCell] {
        return confettiTypes.map { confettiType in
            let cell = CAEmitterCell()
            cell.name = confettiType.name
            
            cell.beginTime = 0.1
            cell.birthRate = 60
            cell.contents = confettiType.image.cgImage
            cell.emissionRange = CGFloat(Double.pi)
            cell.lifetime = confettiLifetime
            cell.spin = 8
            cell.spinRange = 8
            cell.velocityRange = 0
            cell.yAcceleration = 0
            
            cell.setValue("plane", forKey: "particleType")
            cell.setValue(Double.pi, forKey: "orientationRange")
            cell.setValue(Double.pi / 3, forKey: "orientationLongitude")
            cell.setValue(Double.pi / 3, forKey: "orientationLatitude")
            
            return cell
        }
    }

    private func createBehavior(type: String) -> NSObject {
        let behaviorClass = NSClassFromString("CAEmitterBehavior") as! NSObject.Type
        let behaviorWithType = behaviorClass.method(for: NSSelectorFromString("behaviorWithType:"))!
        let castedBehaviorWithType = unsafeBitCast(behaviorWithType, to:(@convention(c)(Any?, Selector, Any?) -> NSObject).self)
        return castedBehaviorWithType(behaviorClass, NSSelectorFromString("behaviorWithType:"), type)
    }

    private func horizontalWaveBehavior() -> Any {
        let behavior = createBehavior(type: "wave")
        behavior.setValue([50, 0, 0], forKeyPath: "force")
        behavior.setValue(0.5, forKeyPath: "frequency")
        return behavior
    }

    private func verticalWaveBehavior() -> Any {
        let behavior = createBehavior(type: "wave")
        behavior.setValue([0, 100, 0], forKeyPath: "force")
        behavior.setValue(3, forKeyPath: "frequency")
        return behavior
    }


    private func attractorBehavior(for emitterLayer: CAEmitterLayer) -> Any {
        let behavior = createBehavior(type: "attractor")
        behavior.setValue("attractor", forKeyPath: "name")
        
        behavior.setValue(-150, forKeyPath: "falloff")
        behavior.setValue(125, forKeyPath: "radius")
        behavior.setValue(10, forKeyPath: "stiffness")
        
        behavior.setValue(CGPoint(x: emitterLayer.emitterPosition.x,
                                  y: emitterLayer.emitterPosition.y + 20),
                          forKeyPath: "position")
        behavior.setValue(-50, forKeyPath: "zPosition")
        
        return behavior
    }

    private func addBehaviors(to layer: CAEmitterLayer) {
        layer.setValue([
            horizontalWaveBehavior(),
            verticalWaveBehavior(),
            attractorBehavior(for: layer)
        ], forKey: "emitterBehaviors")
    }

    private func addAttractorAnimation(to layer: CALayer, generationDuration: Double) {
        let animation = CAKeyframeAnimation()
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animation.duration = 3 * generationDuration
        animation.keyTimes = [0, 0.8]
        animation.values = [80, 5]
        
        layer.add(animation, forKey: "emitterBehaviors.attractor.stiffness")
    }

    private func addBirthrateAnimation(to layer: CALayer, duration: Double) {
        let animation = CABasicAnimation()
        animation.duration = duration
        animation.fromValue = 1
        animation.toValue = 0
        
        layer.add(animation, forKey: "birthRate")
    }

    private func addAnimations(to layer: CAEmitterLayer, generationDuration: Double, confettiLifetime: Float) {
        addAttractorAnimation(to: layer, generationDuration: generationDuration)
        addBirthrateAnimation(to: layer, duration: generationDuration)
//        addDragAnimation(to: layer, generationDuration: generationDuration)
        addGravityAnimation(to: layer, generationDuration: generationDuration)
        addOpacityAnimation(to: layer, confettiLifetime: confettiLifetime)
    }

    private func dragBehavior() -> Any {
        let behavior = createBehavior(type: "drag")
        behavior.setValue("drag", forKey: "name")
        behavior.setValue(3, forKey: "drag")
        
        return behavior
    }

    private func addDragAnimation(to layer: CALayer, generationDuration: Double) {
        let animation = CAKeyframeAnimation()
        animation.duration = 6 * (generationDuration / 2 + 0.5)
        animation.keyTimes = [1, 0.3, 0.5, 0.501, 1]
        animation.values = [3, 2, 0, 0, 0]
//        animation.fromValue = 0
//        animation.toValue = 3
        
        layer.add(animation, forKey:  "emitterBehaviors.drag.drag")
    }

    private func addGravityAnimation(to layer: CALayer, generationDuration: Double) {
        let animation = CAKeyframeAnimation()
        animation.duration = 6 * (generationDuration / 2 + 0.5)
        animation.keyTimes = [0.0, 0.3, 0.5, 1]
        animation.values = [0, 100, 500, -150]
        
        
        for image in confettiTypes {
            layer.add(animation, forKey: "emitterCells.\(image.name).yAcceleration")
        }
    }
    
    private func addOpacityAnimation(to layer: CALayer, confettiLifetime: Float) {
        let animation = CAKeyframeAnimation()
        animation.duration = Double(confettiLifetime)
        animation.keyTimes = [0.0, 0.8, 1.0]
        animation.values = [1.0, 1.0, 0.0]
        
        layer.add(animation, forKey: "opacity")
        layer.opacity = 0
    }

    private func createConfettiLayer(emitterPosition: CGPoint, emitterSize: CGSize, confettiLifetime: Float) -> CAEmitterLayer {
        let emitterLayer = CAEmitterLayer()
        
        emitterLayer.birthRate = 0
        emitterLayer.emitterCells = createConfettiCells(confettiLifetime: confettiLifetime)
        emitterLayer.emitterPosition = emitterPosition //CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.minY - 150)
        emitterLayer.emitterSize =  emitterSize // CGSize(width: 100, height: 120)
        emitterLayer.emitterShape = .sphere
        emitterLayer.frame = UIScreen.main.bounds
        
        emitterLayer.beginTime = CACurrentMediaTime()
        return emitterLayer
    }
    
}

