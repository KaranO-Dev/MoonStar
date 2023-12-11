//
//  GameScene.swift
//  testgame
//
//  Created by Karan Oroumchi on 10/12/23.
//

import SpriteKit
import AVFoundation


class GameScene: SKScene {
    
    private var moonslide = SKSpriteNode()
    private var moonWalkingFrames: [SKTexture] = []
    private var score = 0
    private var scoreLabel = SKLabelNode()
    private var isGameOver = false
    var audioPlayer: AVAudioPlayer?

    
    let customFontName = "customfont"  // Replace with your actual custom font name
    
    override func didMove(to view: SKView) {
        backgroundColor = .systemGray6
        
        addBackground()
        buildMoon()
        spawnStars()
        
        // Add a label to display the score
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 20
        scoreLabel.fontName = customFontName
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 30)
        addChild(scoreLabel)
        
        // Add a reset button
        let resetButton = SKLabelNode(text: "Reset")
        resetButton.fontSize = 20
        resetButton.fontName = customFontName
        resetButton.fontColor = .white
        resetButton.position = CGPoint(x: frame.maxX - 50, y: frame.maxY - 30)
        resetButton.name = "resetButton"
        addChild(resetButton)
        
        if let soundURL = Bundle.main.url(forResource: "test", withExtension: "wav") {
            do {
                try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.prepareToPlay()
            } catch {
                print("Error loading sound file: \(error.localizedDescription)")
            }
        }
    }

    
    func addBackground() {
        let background = SKSpriteNode(imageNamed: "cloudLayer1")
        
        background.size = size
        
        background.position = CGPoint(x: frame.midX, y: frame.minY)
        
        background.zPosition = -1
        
        addChild(background)
    }
    
    // MARK: - Moon code
    func buildMoon() {
        let moonAnimatedAtlas = SKTextureAtlas(named: "MoonSlide")
        var walkFrames: [SKTexture] = []
        
        let numImages = moonAnimatedAtlas.textureNames.count
        for i in 1...numImages {
            let moonTextureName = "MoonSlide\(i)"
            walkFrames.append(moonAnimatedAtlas.textureNamed(moonTextureName))
        }
        moonWalkingFrames = walkFrames
        
        let firstFrameTexture = moonWalkingFrames[0]
        
        let scale: CGFloat = frame.size.width / 1500
        moonslide = SKSpriteNode(texture: firstFrameTexture)
        moonslide.setScale(scale)
        moonslide.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(moonslide)
    }
    
    func animateMoon() {
        moonslide.run(SKAction.repeatForever(
            SKAction.animate(with: moonWalkingFrames,
                             timePerFrame: 0.4,
                             resize: false,
                             restore: true)),
                      withKey:"walkingInPlaceMoon")
    }
    
    func moveMoon(location: CGPoint) {
        var multiplierForDirection: CGFloat
        let moonSpeed = frame.size.width / 5.0
        let moveDifference = CGPoint(x: location.x - moonslide.position.x, y: location.y - moonslide.position.y)
        let distanceToMove = sqrt(moveDifference.x * moveDifference.x + moveDifference.y * moveDifference.y)
        let moveDuration = distanceToMove / moonSpeed
        
        if moveDifference.x < 0 {
            multiplierForDirection = 1.0
        } else {
            multiplierForDirection = -1.0
        }
        moonslide.xScale = abs(moonslide.xScale) * multiplierForDirection
        
        if moonslide.action(forKey: "walkingInPlaceMoon") == nil {
            animateMoon()
        }
        
        let moveAction = SKAction.move(to: location, duration:(TimeInterval(moveDuration)))
        let doneAction = SKAction.run { [weak self] in
            self?.moonMoveEnded()
        }
        let moveActionWithDone = SKAction.sequence([moveAction, doneAction])
        moonslide.run(moveActionWithDone, withKey:"moonMoving")
        
        let touchLocation = location
        let distanceToTouch = CGPoint(x: touchLocation.x - moonslide.position.x, y: touchLocation.y - moonslide.position.y)
        let distance = sqrt(distanceToTouch.x * distanceToTouch.x + distanceToTouch.y * distanceToTouch.y)
        
        if distance < 10.0 {
            provideMoonReachFeedback()
        }
    }
    
    func moonMoveEnded() {
        moonslide.removeAllActions()
    }
    
    // MARK: - Handle touches
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGameOver {
            let touch = touches.first!
            let location = touch.location(in: self)
            
            if nodes(at: location).first(where: { $0.name == "resetButton" }) != nil {
                resetGame()
            } else {
                resetGame()
            }
            return
        }
        
        let touch = touches.first!
        let location = touch.location(in: self)
        
        if let star = nodes(at: location).first(where: { $0 is Star }) as? Star {
            grabStar(star)
        } else if nodes(at: location).first(where: { $0.name == "resetButton" }) != nil {
            resetGame()
        } else {
            provideTouchFeedback()
            moveMoon(location: location)
        }
    }
    
    // MARK: - Haptic Feedback
    
    func provideTouchFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func provideMoonReachFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    // MARK: - Stars
    
    class Star: SKSpriteNode {
        // Add any properties or methods specific to the star class here
    }
    
    func spawnStars() {
        let spawnAction = SKAction.run {
            guard !self.isGameOver else { return }
            
            let starNames = ["star1", "star2", "star3"]
            let randomStarName = starNames.randomElement() ?? "star3"
            
            let star = Star(imageNamed: randomStarName)
            star.position = CGPoint(x: CGFloat.random(in: 0..<self.size.width), y: CGFloat.random(in: self.size.height * 0.4..<self.size.height))
            star.zPosition = 1
            self.addChild(star)
            
            if self.children.filter({ $0 is Star }).count > 20 {
                self.gameOver()
            }
        }
        
        let waitAction = SKAction.wait(forDuration: 1.5) // Adjust the time interval between star spawns
        
        let sequenceAction = SKAction.sequence([spawnAction, waitAction])
        let repeatAction = SKAction.repeatForever(sequenceAction)
        
        run(repeatAction, withKey: "spawnStars")
    }
    
    
    func grabStar(_ star: Star) {
        star.removeFromParent()
        updateScore()
        provideStarGrabFeedback()
        playStarGrabSound()

        if children.filter({ $0 is Star }).count > 20 {
            gameOver()
        }
    }

    func playStarGrabSound() {
        guard let soundURL = Bundle.main.url(forResource: "test", withExtension: "wav") else {
            print("Sound file not found in the bundle.")
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Check for errors during AVAudioPlayer initialization
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Error setting up audio session or playing sound: \(error.localizedDescription)")
        }
    }

    
    // MARK: - Score
    
    func updateScore() {
        score += 1
        scoreLabel.text = "Score: \(score)"
    }
    
    func provideStarGrabFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    // MARK: - Game Over
    
    func gameOver() {
        isGameOver = true
        removeAction(forKey: "spawnStars")

        let gameOverLabel = SKLabelNode(fontNamed: customFontName)
        gameOverLabel.text = "Game Over. Tap to Reset"
        gameOverLabel.fontSize = 50
        gameOverLabel.fontColor = .white
        gameOverLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        gameOverLabel.zPosition = 10  // Set a higher zPosition to make it appear above other elements
        addChild(gameOverLabel)
    }

    
    // Reset the game
    func resetGame() {
        removeAllChildren()
        removeAllActions()
        
        isGameOver = false
        score = 0
        
        addBackground()
        buildMoon()
        spawnStars()
        
        // Add a reset button
        let resetButton = SKLabelNode(text: "Reset")
        resetButton.fontSize = 20
        resetButton.fontColor = .white
        resetButton.position = CGPoint(x: frame.maxX - 50, y: frame.maxY - 30)
        resetButton.name = "resetButton"
        addChild(resetButton)
        
        // Add the score label
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 30)
        addChild(scoreLabel)
    }
}
