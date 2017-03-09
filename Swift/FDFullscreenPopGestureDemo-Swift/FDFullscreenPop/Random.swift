//
//  Algorithm.swift
//
//
//  Created by Yilei He on 14/04/2016.
//  Copyright © 2016 lionhylra.com. All rights reserved.
//

import UIKit

// MARK: - Random number -
extension UInt32 {
    static var random: UInt32 {
        return arc4random()
    }
    
    
    static func random(range: Range<UInt32>) -> UInt32 {
        return arc4random_uniform(range.upperBound - range.lowerBound) + range.lowerBound
    }
}



extension Int {
    static var random: Int {
        return Int(UInt32.random)
    }
    
    
    
    static func random(range: Range<UInt32>) -> Int {
        return Int(UInt32.random(range: range))
    }
}



