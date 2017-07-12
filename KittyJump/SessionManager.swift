//
//  SessionManager.swift
//  KittyJump
//
//  Created by Olivia Brown on 6/12/17.
//  Copyright © 2017 Olivia Brown. All rights reserved.
//

import UIKit

class SharingManager {
    
    // Local Variable
    var lastScores = [Int](repeating: 0, count: 9)
    var userDefaults: UserDefaults = UserDefaults.standard
    
    var highScore: Int = 0 {
        didSet {
            userDefaults.set(highScore, forKey: "HighScore")
        }
    }
    var currentScore: Int = 0 {
        didSet {
            changeLastScores(score: currentScore)
        }
    }
    var lifetimeScore: Int = 0 {
        didSet {
            userDefaults.set((lifetimeScore), forKey: "LifetimeScore")
        }
    }
    var itemStates: [String] = ["inStore", "inStore", "inStore", "inStore", "inStore"] {
        didSet {
            userDefaults.set(itemStates, forKey: "itemStates")
        }
    }
    var catImageString: String = "kitty.png" {
        didSet {
            userDefaults.set(catImageString, forKey: "CatImageString")
        }
    }
    static let sharedInstance = SharingManager()
    
    private init() {
        let storedHighScore = userDefaults.integer(forKey: "HighScore")
        if storedHighScore != 0 {
            highScore = storedHighScore
        }
        else {
            userDefaults.set(highScore, forKey: "HighScore")
        }
        let storedLastScores = userDefaults.array(forKey: "LastScores") as? [Int]
        if storedLastScores != nil {
            lastScores = storedLastScores!
        }
        else {
            userDefaults.set(lastScores, forKey: "LastScores")
        }
        let storedLifetimeScore = userDefaults.integer(forKey: "LifetimeScore")
        if storedLifetimeScore != 0 {
            lifetimeScore = storedLifetimeScore
        }
        else {
            userDefaults.set(lifetimeScore, forKey: "LifetimeScore")
        }
        let storedItemStates = userDefaults.array(forKey: "itemStates")
        if storedItemStates != nil {
            itemStates = storedItemStates as! [String]
        }
        else {
            userDefaults.set(itemStates, forKey: "itemStates")
        }
        let storedCatImageString = userDefaults.string(forKey: "CatImageString")
        if storedCatImageString != nil {
            catImageString = storedCatImageString!
        }
        else {
            userDefaults.set(catImageString, forKey: "CatImageString")
        }
    }
    
    func changeLastScores(score: Int) {
        var temp1, temp2: Int
        temp1 = score
        for i in 0..<lastScores.count {
            temp2 = lastScores[i]
            lastScores[i] = temp1
            temp1 = temp2
        }
        userDefaults.set(lastScores, forKey: "LastScores")
    }
}
