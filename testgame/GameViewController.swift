//
//  GameViewController.swift
//  testgame
//
//  Created by Karan Oroumchi on 10/12/23.
//

import UIKit
import SpriteKit
import GameKit

class GameViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = view as? SKView {
            // Set the frame rate to 120fps
            view.preferredFramesPerSecond = 120
            
            // Additional configuration
            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsNodeCount = true
            view.showsQuadCount = true
            view.showsPhysics = true
                        
            // Create the scene programmatically
            let scene = GameScene(size: view.bounds.size)
            scene.scaleMode = .resizeFill
            view.presentScene(scene)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
