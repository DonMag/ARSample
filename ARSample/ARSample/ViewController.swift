//
//  ViewController.swift
//  ARSample
//
//  Created by Don Mag on 10/25/23.
//

import UIKit
import ARKit

class aPresetsViewController: UIViewController, ARSCNViewDelegate, ARCoachingOverlayViewDelegate, ARSessionDelegate {

	@IBOutlet weak var sceneView: ARSCNView!

	var grassImage: UIImage!

	let colors: [UIColor] = [
		.red, .green, .cyan, .yellow, .magenta, .systemPink,
	]
	
	let y: Float = -0.1
	let z: Float = -0.2
	
	// triangle
	lazy var triangle: [SCNVector3] = [
		.init(x:  0.0, y: y, z: z),
		.init(x:  0.1, y: y, z: z - 0.2),
		.init(x: -0.1, y: y, z: z - 0.2),
	]
	// diamond
	lazy var diamond: [SCNVector3] = [
		.init(x:  0.0, y: y, z: z),
		.init(x:  0.1, y: y, z: z - 0.2),
		.init(x:  0.0, y: y, z: z - 0.3),
		.init(x: -0.1, y: y, z: z - 0.2),
	]
	// 5-sided polygon
	lazy var polygon: [SCNVector3] = [
		.init(x:  0.0, y: y, z: z),
		.init(x:  0.1, y: y, z: z - 0.1),
		.init(x:  0.05, y: y, z: z - 0.2),
		.init(x:  -0.05, y: y, z: z - 0.2),
		.init(x: -0.1, y: y, z: z - 0.1),
	]
	
	var thePositions: [SCNVector3] = []
	var posNodes: [SCNNode] = []
	var shapeNode: SCNNode!
	var iCounter: Int = 0
	var rCounter: Int = 0
	var r: Float = 0.0

	override func viewDidLoad() {
		super.viewDidLoad()
		
		guard let img = UIImage(named: "grass") else {
			fatalError("Could not load grass image!")
		}
		grassImage = img
		
		//Setup an AR SceneView Session
		sceneView.delegate = self
		sceneView.session.delegate = self
		let Config = ARWorldTrackingConfiguration()
		Config.planeDetection = [.horizontal, .vertical]
		sceneView.session.run(Config,  options: [.resetTracking, .removeExistingAnchors])

	}

	@IBAction func typeTapped(_ sender: UIButton) {

		posNodes = []
		
		switch sender.configuration?.title {
		case "Triangle":
			thePositions = triangle
			()
			
		case "Diamond":
			thePositions = diamond
			()
			
		case "Polygon":
			thePositions = polygon
			()
			
		default:
			thePositions = []
			()
		}
		
		sceneView.scene.rootNode.childNodes.forEach { n in
			n.removeFromParentNode()
		}

		if thePositions.isEmpty { return }
		
		preBuild()
		
		iCounter = -1
		
		Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { t in
			self.iCounter += 1
			if self.iCounter < self.posNodes.count {
				self.addPosition()
			} else if self.iCounter == self.posNodes.count {
				self.addShape()
				self.r = 0.0
			} else {
				self.r += 0.05
				if self.r < 0.51 {
					self.rotateShape()
				} else {
					t.invalidate()
				}
			}
		})
	}
	
	func preBuild() {

		for (p, c) in zip(thePositions, colors) {
			let sphere = SCNSphere(color: c, radius: 0.01)
			let node = SCNNode(geometry: sphere)
			node.position = p
			posNodes.append(node)
		}
		
		let path = UIBezierPath()
		
		let xOff = posNodes[0].position.x
		let zOff = posNodes[0].position.z
		
		// Iterate through the sphere nodes array
		for (index, nodes) in posNodes.enumerated() {
			let position = nodes.position
			
			// "normalize" the x and z coordinates
			let nx = position.x - xOff
			let nz = position.z - zOff
			if index == 0 {
				// Move to the starting position
				path.move(to: CGPoint(x: CGFloat(nx), y: CGFloat(nz)))
			} else {
				// Add a line segment to the next sphere node
				path.addLine(to: CGPoint(x: CGFloat(nx), y: CGFloat(nz)))
			}
			
		}
		
		path.close()
		
		guard let gImg = UIImage(named: "grass") else {
			fatalError()
		}
		
		// couple different materials so we can see the geometry of the shape
		
		let grassMat = SCNMaterial()
		grassMat.diffuse.contents = gImg
		
		let cyanMaterial = SCNMaterial()
		cyanMaterial.diffuse.contents = UIColor.cyan
		
		let orangeMaterial = SCNMaterial()
		orangeMaterial.diffuse.contents = UIColor.orange
		
		let redMaterial = SCNMaterial()
		redMaterial.diffuse.contents = UIColor.red
		
		let shape = SCNShape(path: path, extrusionDepth: 0.005)
		
		shape.materials = [orangeMaterial, grassMat, cyanMaterial]
		
		shapeNode = SCNNode(geometry: shape)
		
		if let fNode = posNodes.first {
			shapeNode.position = fNode.position
		}
		
	}

	func addPosition() {
		self.sceneView.scene.rootNode.addChildNode(self.posNodes[self.iCounter])
	}
	func addShape() {
		self.sceneView.scene.rootNode.addChildNode(shapeNode)
	}
	func rotateShape() {
		self.shapeNode.rotation = .init(x: 1.0, y: 0.0, z: 0.0, w: .pi * self.r)
	}

}

class PresetsViewController: UIViewController, ARSCNViewDelegate, ARCoachingOverlayViewDelegate, ARSessionDelegate {
	
	@IBOutlet var sceneView: ARSCNView!
	@IBOutlet var animSwitch: UISwitch!

	var grassImage: UIImage!
	
	let colors: [UIColor] = [
		.red, .green, .cyan, .yellow, .magenta, .systemPink,
		.red, .green, .cyan, .yellow, .magenta, .systemPink,
		.red, .green, .cyan, .yellow, .magenta, .systemPink,
	]
	
	let y: Float = -0.2
	let z: Float = -0.35
	
	// triangle
	lazy var triangle: [SCNVector3] = [
		.init(x:  0.0, y: y, z: z - 0.0),
		.init(x:  0.1, y: y, z: z - 0.2),
		.init(x: -0.1, y: y, z: z - 0.2),
	]
	// diamond
	lazy var diamond: [SCNVector3] = [
		.init(x:  0.1, y: y, z: z - 0.2),
		.init(x:  0.0, y: y, z: z - 0.3),
		.init(x: -0.1, y: y, z: z - 0.2),
		.init(x:  0.0, y: y, z: z - 0.0),
	]
	// complex polygon
	lazy var polygon: [SCNVector3] = [
		.init(x: -0.04, y: y, z: z - 0.61),
		.init(x:  0.16, y: y, z: z - 0.41),
		.init(x:  0.06, y: y, z: z - 0.31),
		.init(x:  0.06, y: y, z: z - 0.21),
		.init(x:  0.10, y: y, z: z - 0.11),
		.init(x:  0.06, y: y, z: z - 0.01),
		.init(x: -0.04, y: y, z: z - 0.15),
		.init(x: -0.14, y: y, z: z - 0.01),
		.init(x: -0.24, y: y, z: z - 0.21),
		.init(x: -0.14, y: y, z: z - 0.41),
		.init(x: -0.24, y: y, z: z - 0.61),
	]
	
	var thePositions: [SCNVector3] = []
	var posNodes: [SCNNode] = []
	var shapeNode: SCNNode!
	var iCounter: Int = 0
	var rCounter: Int = 0
	var r: Float = 0.0
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		guard let img = UIImage(named: "grass") else {
			fatalError("Could not load grass image!")
		}
		grassImage = img
		
		//Setup an AR SceneView Session
		sceneView.delegate = self
		sceneView.session.delegate = self
		let config = ARWorldTrackingConfiguration()
		config.planeDetection = [.horizontal, .vertical]
		sceneView.session.run(config,  options: [.resetTracking, .removeExistingAnchors])
		
	}
	
	@IBAction func resetTapped(_ sender: UIButton) {
		posNodes = []
		sceneView.scene.rootNode.childNodes.forEach { n in
			n.removeFromParentNode()
		}
		sceneView.session.pause()
		let config = ARWorldTrackingConfiguration()
		config.planeDetection = [.horizontal, .vertical]
		sceneView.session.run(config,  options: [.resetTracking, .removeExistingAnchors])
	}

	@IBAction func typeTapped(_ sender: UIButton) {
		
		posNodes = []
		
		switch sender.configuration?.title {
		case "Triangle":
			thePositions = triangle
			()
			
		case "Diamond":
			thePositions = diamond
			()
			
		case "Polygon":
			thePositions = polygon
			()
			
		default:
			thePositions = []
			()
		}
		
		sceneView.scene.rootNode.childNodes.forEach { n in
			n.removeFromParentNode()
		}
		
		if thePositions.isEmpty { return }
		
		preBuild()
		
		iCounter = -1
		addPositions()
	}
	
	func preBuild() {
		
		for (p, c) in zip(thePositions, colors) {
			let sphere = SCNSphere(color: c, radius: 0.01)
			let node = SCNNode(geometry: sphere)
			node.position = p
			posNodes.append(node)
		}
		
		let path = UIBezierPath()
		
		let xOff = posNodes[0].position.x
		let zOff = posNodes[0].position.z
		
		// Iterate through the sphere nodes array
		for (index, nodes) in posNodes.enumerated() {
			let position = nodes.position
			
			// "normalize" the x and z coordinates
			//	so the first point is at 0,0
			let nx = position.x - xOff
			let nz = position.z - zOff
			if index == 0 {
				// Move to the starting position
				path.move(to: CGPoint(x: CGFloat(nx), y: CGFloat(nz)))
			} else {
				// Add a line segment to the next sphere node
				path.addLine(to: CGPoint(x: CGFloat(nx), y: CGFloat(nz)))
			}
			
		}
		
		path.close()
		
		// couple different materials so we can see the geometry of the shape
		
		let grassMat = SCNMaterial()
		grassMat.diffuse.contents = grassImage
		
		let cyanMaterial = SCNMaterial()
		cyanMaterial.diffuse.contents = UIColor.cyan
		
		let orangeMaterial = SCNMaterial()
		orangeMaterial.diffuse.contents = UIColor.orange
		
		let shape = SCNShape(path: path, extrusionDepth: 0.005)
		
		shape.materials = [orangeMaterial, grassMat, cyanMaterial]
		
		shapeNode = SCNNode(geometry: shape)
		
		if let fNode = posNodes.first {
			shapeNode.position = fNode.position
		}
		
	}
	
	func addPositions() {
		Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { t in
			self.iCounter += 1
			if self.iCounter < self.posNodes.count {
				self.sceneView.scene.rootNode.addChildNode(self.posNodes[self.iCounter])
				if self.iCounter > 0 {
					let lineBetweenNodes = LineNode(from: self.posNodes[self.iCounter - 1].position, to: self.posNodes[self.iCounter].position, lineColor: UIColor.systemBlue)
					self.sceneView.scene.rootNode.addChildNode(lineBetweenNodes)
				}
			} else {
				t.invalidate()
				let lineBetweenNodes = LineNode(from: self.posNodes[self.iCounter - 1].position, to: self.posNodes[0].position, lineColor: UIColor.systemBlue)
				self.sceneView.scene.rootNode.addChildNode(lineBetweenNodes)
				self.addShape()
			}
		})
	}
	func addShape() {
		self.sceneView.scene.rootNode.addChildNode(self.shapeNode)
		self.r = 0.0
		if animSwitch.isOn {
			DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
				self.rotateShape()
			})
		} else {
			self.shapeNode.rotation = .init(x: 1.0, y: 0.0, z: 0.0, w: .pi * 0.5)
		}
	}
	func rotateShape() {
		Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { t in
			self.r += 0.025
			if self.r < 0.51 {
				self.shapeNode.rotation = .init(x: 1.0, y: 0.0, z: 0.0, w: .pi * self.r)
			} else {
				t.invalidate()
			}
		})
	}
	
}


