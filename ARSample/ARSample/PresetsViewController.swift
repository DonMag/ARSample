//
//  PresetsViewController.swift
//  ARSample
//
//  Created by Don Mag on 10/26/23.
//

import UIKit
import ARKit

class PresetsViewController: UIViewController, ARSCNViewDelegate, ARCoachingOverlayViewDelegate, ARSessionDelegate {
	
	@IBOutlet var sceneView: ARSCNView!
	@IBOutlet var animSwitch: UISwitch!
	
	var grassImage: UIImage!
	let grassMat = SCNMaterial()
	let cyanMaterial = SCNMaterial()
	let orangeMaterial = SCNMaterial()
	
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
	var r: Float = 0.0
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		guard let img = UIImage(named: "grass") else {
			fatalError("Could not load grass image!")
		}
		grassImage = img
		
		// couple different materials so we can see the geometry of the shape
		grassMat.diffuse.contents = grassImage
		cyanMaterial.diffuse.contents = UIColor.cyan
		orangeMaterial.diffuse.contents = UIColor.orange
		
		//Setup an AR SceneView Session
		sceneView.delegate = self
		sceneView.session.delegate = self
		let config = ARWorldTrackingConfiguration()
		config.planeDetection = [.horizontal, .vertical]
		sceneView.session.run(config,  options: [.resetTracking, .removeExistingAnchors])
		
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		sceneView.session.pause()
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
		
		let shape = SCNShape(path: path, extrusionDepth: 0.001)
		
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


