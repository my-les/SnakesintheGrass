import SpriteKit
import UIKit

class GameScene: SKScene {
    private var snake: [(Int, Int)] = []
    private var food: SKSpriteNode?
    private var moveDirection: CGVector = CGVector(dx: 1, dy: 0)
    private var nextMoveTime: TimeInterval = 0
    private var moveSpeed: TimeInterval = 0.1
    private var score: Int = 0
    private var scoreLabel: SKLabelNode?


    private var level: Int = 1
    private var baseSpeed: TimeInterval = 0.1
    private let speedIncreaseFactor: Double = 0.85
    private var levelLabel: SKLabelNode?

    private let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let notificationFeedbackGenerator = UINotificationFeedbackGenerator()


    private let gridSize: CGFloat = 20
    private let gridWidth: Int
    private let gridHeight: Int
    private var isGameOver: Bool = false

    override init(size: CGSize) {
        gridWidth = Int(size.width / gridSize)
        gridHeight = Int(size.height / gridSize)
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        backgroundColor = .white
        setupGame()
        impactFeedbackGenerator.prepare()
        notificationFeedbackGenerator.prepare()

        // Adding swipe gesture recognizers
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeUp.direction = .up
        view.addGestureRecognizer(swipeUp)

        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)

        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
    }

    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        switch gesture.direction {
        case .up:
            if moveDirection.dy == 0 { moveDirection = CGVector(dx: 0, dy: 1) }
        case .down:
            if moveDirection.dy == 0 { moveDirection = CGVector(dx: 0, dy: -1) }
        case .left:
            if moveDirection.dx == 0 { moveDirection = CGVector(dx: -1, dy: 0) }
        case .right:
            if moveDirection.dx == 0 { moveDirection = CGVector(dx: 1, dy: 0) }
        default:
            break
        }
    }

    private func setupGame() {
        snake.removeAll()
        food?.removeFromParent()
        score = 0

        level = 1
        moveSpeed = baseSpeed

        moveDirection = CGVector(dx: 1, dy: 0)
        isGameOver = false

        // Initial snake position
        let startPosition = CGPoint(x: CGFloat(gridWidth / 2), y: CGFloat(gridHeight / 2))
        addSnakePart(at: startPosition)
        spawnFood()
        setupScoreLabel()
    }

    private func addSnakePart(at position: CGPoint) {
        let gridPosition = (Int(position.x / gridSize), Int(position.y / gridSize))
        snake.insert(gridPosition, at: 0)
    }

    private func spawnFood() {
        food?.removeFromParent()
        let texture = SKTexture(imageNamed: "apple")
        food = SKSpriteNode(texture: texture, size: CGSize(width: gridSize, height: gridSize))
        let randomX = CGFloat(Int.random(in: 0..<gridWidth)) * gridSize
        let randomY = CGFloat(Int.random(in: 0..<gridHeight)) * gridSize
        food?.position = CGPoint(x: randomX, y: randomY)
        addChild(food!)
    }

    private func setupScoreLabel() {
        scoreLabel = SKLabelNode(fontNamed: "CourierNewPS-BoldMT")
        scoreLabel?.fontSize = 16
        scoreLabel?.fontColor = .black
        scoreLabel?.position = CGPoint(x: size.width / 2, y: size.height - 95)
        scoreLabel?.text = "Score: 0 | Level: 1"
        addChild(scoreLabel!)
    }

    override func update(_ currentTime: TimeInterval) {
        if !isGameOver && currentTime > nextMoveTime {
            moveSnake()
            nextMoveTime = currentTime + moveSpeed
        }
    }

    private func moveSnake() {
        guard let head = snake.first else { return }
        let newHead = (
            (head.0 + Int(moveDirection.dx) + gridWidth) % gridWidth,
            (head.1 + Int(moveDirection.dy) + gridHeight) % gridHeight
        )

        // Check if the snake eats the food
        let foodPosition = (Int(food?.position.x ?? 0) / Int(gridSize), Int(food?.position.y ?? 0) / Int(gridSize))
        if newHead == foodPosition {
            impactFeedbackGenerator.impactOccurred()

            snake.insert(newHead, at: 0)
            spawnFood()
            updateScore()
        } else {
            snake.insert(newHead, at: 0)
            snake.removeLast()
        }

        if checkForCollisions() {
            notificationFeedbackGenerator.notificationOccurred(.error)
            gameOver()
        }

        updateSnakeDisplay()
    }

    private func checkForCollisions() -> Bool {
        guard let head = snake.first else { return false }
        // Check if snake collides with itself
        return snake.dropFirst().contains { $0 == head }
    }

    private func updateScore() {
        score += 10
        scoreLabel?.text = "Score: \(score) | Level: \(level)"

        // Calculate new level
        let newLevel = (score / 50) + 1
        if newLevel != level {
            level = newLevel
            updateSpeedForLevel()
        }
    }

    private func updateSpeedForLevel() {
        // Every third level, increase speed
        if level % 3 == 0 {
            // Calculate how many speed increases have occurred
            let speedIncreases = level / 3
            // Apply the speed increase factor for each increment
            let newSpeed = baseSpeed * pow(speedIncreaseFactor, Double(speedIncreases))
            // Ensure speed doesn't get too fast (optional)
             moveSpeed = max(newSpeed, 0.05)
        }
    }

    private func gameOver() {
        isGameOver = true
        showGameOverAlert()
    }

    private func showGameOverAlert() {
        let alertController = UIAlertController(title: "never backdoor yourself twin", message: "your score: \(score) #numbers... you reached level: \(level) slick. good job!", preferredStyle: .alert)

        let playAgainAction = UIAlertAction(title: "play again typeshi", style: .default) { [weak self] _ in
            self?.restartGame()
        }

        let shareScoreAction = UIAlertAction(title: "share score", style: .default) { [weak self] _ in
            self?.shareScore()
        }

        let mainMenuAction = UIAlertAction(title: "main menu", style: .default) { [weak self] _ in
            self?.goToMainMenu()
        }

        alertController.addAction(playAgainAction)
        alertController.addAction(shareScoreAction)
        alertController.addAction(mainMenuAction)

        if let viewController = self.view?.window?.rootViewController {
            viewController.present(alertController, animated: true, completion: nil)
        }
    }

    private func restartGame() {
        removeAllChildren()
        setupGame()
    }

    private func shareScore() {
        let activityViewController = UIActivityViewController(
            activityItems: ["I scored \(score) points in slyme!"],
            applicationActivities: nil
        )

        if let viewController = self.view?.window?.rootViewController {
            viewController.present(activityViewController, animated: true, completion: nil)
        }
    }

    private func goToMainMenu() {
        // Placeholder for now, as we don't have a main menu yet
        print("Going to main menu")
    }

    private func moveTowardsFood() {
        guard let head = snake.first, let food = food else { return }
        let foodPosition = (Int(food.position.x / gridSize), Int(food.position.y / gridSize))
        let dx = foodPosition.0 - head.0
        let dy = foodPosition.1 - head.1

        let newDirection: CGVector
        if abs(dx) > abs(dy) {
            newDirection = dx > 0 ? CGVector(dx: 1, dy: 0) : CGVector(dx: -1, dy: 0)
        } else {
            newDirection = dy > 0 ? CGVector(dx: 0, dy: 1) : CGVector(dx: 0, dy: -1)
        }

        // Prevent 180-degree turns
        if newDirection.dx != -moveDirection.dx || newDirection.dy != -moveDirection.dy {
            moveDirection = newDirection
        }
    }

    private func updateSnakeDisplay() {
        // Remove existing snake nodes
        children.filter { $0.name == "snakeSegment" }.forEach { $0.removeFromParent() }

        // Create new snake nodes with proper textures
        for (index, currentPosition) in snake.enumerated() {
            let previousPosition = index > 0 ? snake[index - 1] : nil
            let nextPosition = index < snake.count - 1 ? snake[index + 1] : nil

            let partType: SnakePartType
            if index == 0 {
                partType = .head
            } else if index == snake.count - 1 {
                partType = .tail
            } else {
                partType = .body
            }

            let textureName = partType.getTextureName(
                previousPosition: previousPosition,
                currentPosition: currentPosition,
                nextPosition: nextPosition
            )

            //print("typeshit \(textureName)")

            let texture = SKTexture(imageNamed: textureName)
            let node = SKSpriteNode(texture: texture, size: CGSize(width: gridSize, height: gridSize))
            node.position = CGPoint(x: CGFloat(currentPosition.0) * gridSize,
                                    y: CGFloat(currentPosition.1) * gridSize)
            node.name = "snakeSegment"
            //node.color = .black
            //print("this is the node: \(node)")
            addChild(node)
        }
    }

    private enum SnakePartType {
        case head
        case body
        case tail

        func getTextureName(previousPosition: (Int, Int)?,
                            currentPosition: (Int, Int),
                            nextPosition: (Int, Int)?) -> String {
            switch self {
            case .head:
                guard let next = nextPosition else {
                    print("heads")
                    return "head_up"
                }
                let dx = currentPosition.0 - next.0
                let dy = currentPosition.1 - next.1
                //print("this is dy: \(dy) and this is dx: \(dx)")
                if dx > 0 { return "head_right" }
                if dx < 0 { return "head_left" }
                if dy > 0 { return "head_up" }
                //print("gimmie head")
                return "head_down"

            case .tail:
                guard let prev = previousPosition else { return "tail_left" }
                let dx = prev.0 - currentPosition.0
                let dy = prev.1 - currentPosition.1
                if dx > 0 { return "tail_left" }
                if dx < 0 { return "tail_right" }
                if dy > 0 { return "tail_down" }
                //print("tookthatthangupshootymake it roll")
                return "tail_up"

            case .body:
                guard let prev = previousPosition, let next = nextPosition else {
                    print("1")
                    return "body_horizontal"
                }

                let isVertical = prev.0 == next.0
                let isHorizontal = prev.1 == next.1

                if isVertical { return "body_vertical" }
                if isHorizontal { return "body_horizontal" }

                // Handle corners
                let dx1 = currentPosition.0 - prev.0
                let dy1 = currentPosition.1 - prev.1
                let dx2 = next.0 - currentPosition.0
                let dy2 = next.1 - currentPosition.1

                switch (dx1, dy1, dx2, dy2) {
                case (1, 0, 0, 1), (0, -1, -1, 0):

                    print("this")
                    return "body_topleft"
                case (-1, 0, 0, 1), (0, -1, 1, 0):
                    print("that")
                    return "body_topright"
                case (1, 0, 0, -1), (0, 1, -1, 0):
                    print("typeshit")
                    return "body_bottomleft"
                case (-1, 0, 0, -1), (0, 1, 1, 0):
                    print("umm")
                    return "body_bottomright"
                default:
                    print("we got here")
                    return "body_vertical"
                }
            }
        }
    }
}
