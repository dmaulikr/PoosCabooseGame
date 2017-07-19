//
//  GameSettings.swift
//  Mookie
//
//  Created by osc_mac on 9/22/16.
//  Copyright © 2016 com.scrape.clone. All rights reserved.
//

import Foundation
import UIKit

var g_bPause : Bool = false
var g_bFinishJump : Bool = false;

func load()
{
    let userDefault = UserDefaults.standard
    
    let bLoad : Bool = userDefault.bool(forKey: "kittykittykitty")
    
    if ( !bLoad ) {
        
        userDefault.set(true, forKey: "kittykittykitty")
        
        g_bPause = false
        
        userDefault.set(g_bPause, forKey: "kitty_game_pause")
        
        userDefault.synchronize()
        
    }
    else {
        
        g_bPause = userDefault.bool(forKey: "kitty_game_pause")
    }
}

func setPauseState()
{
    let userDefault = UserDefaults.standard
    userDefault.set(g_bPause, forKey: "kitty_game_pause")
    userDefault.synchronize()
}

func getPauseState()
{
    let userDefault = UserDefaults.standard
    g_bPause = userDefault.bool(forKey: "kitty_game_pause")
}
