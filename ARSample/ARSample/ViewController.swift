//
//  ViewController.swift
//  ARSample
//
//  Created by Don Mag on 10/25/23.
//

import UIKit
import ARKit

class PresetsViewController: UIViewController, ARSCNViewDelegate, ARCoachingOverlayViewDelegate, ARSessionDelegate {

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

extension SCNSphere {
	convenience init(color: UIColor, radius: CGFloat) {
		self.init(radius: radius)
		let material = SCNMaterial()
		material.diffuse.contents = color
		materials = [material]
		
	}
}

class LineNode: SCNNode {
	
	init(from vectorA: SCNVector3, to vectorB: SCNVector3, lineColor color: UIColor) {
		super.init()
		let height = self.distance(from: vectorA, to: vectorB)
		self.position = vectorA
		let nodeVector2 = SCNNode()
		nodeVector2.position = vectorB
		let nodeZAlign = SCNNode()
		nodeZAlign.eulerAngles.x = Float.pi/2
		let box = SCNBox(width: 0.003, height: height, length: 0.001, chamferRadius: 0)
		let material = SCNMaterial()
		material.diffuse.contents = color
		box.materials = [material]
		let nodeLine = SCNNode(geometry: box)
		nodeLine.position.y = Float(-height/2) + 0.001
		nodeZAlign.addChildNode(nodeLine)
		self.addChildNode(nodeZAlign)
		self.constraints = [SCNLookAtConstraint(target: nodeVector2)]
		
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	func distance(from vectorA: SCNVector3, to vectorB: SCNVector3)-> CGFloat
	{
		return CGFloat(sqrt((vectorA.x - vectorB.x) * (vectorA.x - vectorB.x) +   (vectorA.y - vectorB.y) * (vectorA.y - vectorB.y) + (vectorA.z - vectorB.z) * (vectorA.z - vectorB.z)))
		
	}
}

extension SCNVector3 {
	static func positionFrom(matrix: matrix_float4x4) -> SCNVector3 {
		let column = matrix.columns.3
		return SCNVector3(column.x, column.y, column.z)
	}
}
