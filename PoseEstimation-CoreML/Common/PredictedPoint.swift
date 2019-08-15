//
//  PredictedPoint.swift
//  PoseEstimation-CoreML
//
//  Created by Doyoung Gwak on 27/06/2019.
//  Copyright © 2019 tucan9389. All rights reserved.
//

import CoreGraphics
import Foundation

struct PredictedPoint {
    let maxPoint: CGPoint
    let maxConfidence: Double
    
    init(maxPoint: CGPoint, maxConfidence: Double) {
        self.maxPoint = maxPoint
        self.maxConfidence = maxConfidence
    }
    
    init(capturedPoint: CapturedPoint) {
        self.maxPoint = capturedPoint.point
        self.maxConfidence = 1
    }
}

class CapturedPoint: NSObject, NSCoding {
    let point: CGPoint
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(point, forKey: "point")
    }
    
    required init?(coder aDecoder: NSCoder) {
        point = aDecoder.decodeObject(forKey: "point") as? CGPoint ?? aDecoder.decodeCGPoint(forKey: "point")
    }
    
    init(predictedPoint: PredictedPoint) {
        point = predictedPoint.maxPoint
    }
}

struct CapturedPointAngle {
    static let angleIndicesArray = [
        (0, 1, 2),
        (1, 2, 3),
        (2, 3, 4),
        (0, 1, 5),
        (1, 5, 6),
        (5, 6, 7)
    ]
}

extension Array where Element == CapturedPoint? {
    func match(with predictedPoints: [PredictedPoint?]) -> CGFloat {
        guard predictedPoints.count >= 8, self.count >= 8 else {
            return -100000
        }
        
        var numberOfValidCaputrePointAngle = 0
        var totalAngleLoss: CGFloat = 0
        
        for (index1, index2, index3) in CapturedPointAngle.angleIndicesArray {
            guard let p1 = self[index1]?.point,
                let center = self[index2]?.point,
                let p2 = self[index3]?.point else {
                continue
            }
            
            numberOfValidCaputrePointAngle += 1
            
            let angle = center.angle(with: p1, and: p2)
            var targetAngle: CGFloat? = nil
            if let p1 = predictedPoints[index1]?.maxPoint,
                let center = predictedPoints[index2]?.maxPoint,
                let p2 = predictedPoints[index3]?.maxPoint {
                targetAngle = center.angle(with: p1, and: p2)
            }
            
            var angleLoss = CGFloat.pi
            if let targetAngle = targetAngle {
                angleLoss = abs(targetAngle - angle)
            }
            totalAngleLoss += angleLoss
        }
        
        if numberOfValidCaputrePointAngle == 0 {
            return 0
        } else {
            return 1 - (totalAngleLoss / CGFloat(numberOfValidCaputrePointAngle)) / CGFloat.pi
        }
    }
}

extension CGPoint {
    func angle(with p1: CGPoint, and p2: CGPoint) -> CGFloat {
        let center = self
        let transformedP1 = CGPoint(x: p1.x - center.x, y: p1.y - center.y)
        let transformedP2 = CGPoint(x: p2.x - center.x, y: p2.y - center.y)
        
        let angleToP1 = atan2(transformedP1.y, transformedP1.x)
        let angleToP2 = atan2(transformedP2.y, transformedP2.x)
        
        return normaliseToInteriorAngle(with: angleToP2 - angleToP1)
    }
    
    func normaliseToInteriorAngle(with angle: CGFloat) -> CGFloat {
        var angle = angle
        if (angle < 0) { angle += (2*CGFloat.pi) }
        if (angle > CGFloat.pi) { angle = 2*CGFloat.pi - angle }
        return angle
    }
}
