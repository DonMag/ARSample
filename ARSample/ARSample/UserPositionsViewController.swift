//
//  UserPositionsViewController.swift
//  ARSample
//
//  Created by Don Mag on 10/26/23.
//

import UIKit
import ARKit

class UserPositionsViewController: UIViewController, ARSCNViewDelegate, ARCoachingOverlayViewDelegate, ARSessionDelegate {
	
	@IBOutlet weak var sceneView: ARSCNView!
	@IBOutlet var constrainSwitch: UISwitch!
	@IBOutlet var animSwitch: UISwitch!
	
	var grassImage: UIImage!
	let grassMat = SCNMaterial()
	let cyanMaterial = SCNMaterial()
	let orangeMaterial = SCNMaterial()

	var nodes: [SCNNode] = []

	var startingNode : SCNNode!
	var lineNode : LineNode!
	
	var shapeNode: SCNNode!
	
	var r: Float = 0.0
	
	let coachingOverlay = ARCoachingOverlayView()
	var isEditingEnabled = true
	
	var session: ARSession {
		return sceneView.session
	}
	
	// MARK: - View Didload
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
		let Config = ARWorldTrackingConfiguration()
		Config.planeDetection = [.horizontal, .vertical]
		sceneView.session.run(Config,  options: [.resetTracking, .removeExistingAnchors])
		
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		sceneView.session.pause()
	}
	
	@IBAction func resetTapped(_ sender: UIButton) {
		nodes = []
		sceneView.scene.rootNode.childNodes.forEach { n in
			n.removeFromParentNode()
		}
		sceneView.session.pause()
		let config = ARWorldTrackingConfiguration()
		config.planeDetection = [.horizontal, .vertical]
		sceneView.session.run(config,  options: [.resetTracking, .removeExistingAnchors])
		isEditingEnabled = true
		startingNode = nil
	}
	
	// MARK: - Draw the spheres to create a Shape
	
	@IBAction func addPosTapped(_ sender: UIButton) {
		let screenPoint = CGPoint(x: sceneView.bounds.midX, y: sceneView.bounds.midY)
		guard let raycastQuery = sceneView.raycastQuery(from: screenPoint, allowing: .estimatedPlane, alignment: .any) else {return}
		let raycastResults = sceneView.session.raycast(raycastQuery)
		
		guard let firstResult = raycastResults.first  else {  return }
		
		let position = SCNVector3.positionFrom(matrix: firstResult.worldTransform)
		
		let sphere = SCNSphere(color: .systemBlue, radius: 0.01)
		let node = SCNNode(geometry: sphere)
		
		node.position = position
		
		let lastNode = nodes.last
		
		sceneView.scene.rootNode.addChildNode(node)
		
		// Add the Sphere to the list.
		nodes.append(node)
		
		// Setting our starting point for drawing a line in real time
		self.startingNode = nodes.last
		
		if lastNode != nil {
			// If there are 2 nodes or more
			
			if nodes.count >= 2 {
				// Create a node line between the nodes
				let lineBetweenNodes = LineNode(from: (lastNode?.position)!,   to: node.position, lineColor: UIColor.systemBlue)
				
				// Add the Node to the scene.
				sceneView.scene.rootNode.addChildNode(lineBetweenNodes)
			}
		}
		
	}
	
	//then we have the imageView that the user can assign to the drawn path ,
	
	// MARK: - handle Tap on ImageView
	
	@IBAction func fillTapped(_ sender: UIButton) {
		if startingNode === nodes.last {
			// Create a line segment from the last node to the first node
			if let firstNode = nodes.first {
				let lineBetweenNodes = LineNode(from: startingNode.position, to: firstNode.position, lineColor: UIColor.systemBlue)
				sceneView.scene.rootNode.addChildNode(lineBetweenNodes)
				
				//Add Image to the Closed Path
				addImage()
			}
		}
		
	}
	
	// MARK: - Add Image function
	
	func addImage(){
		isEditingEnabled = false
		
		// if useAverageY switch is On
		//	get the average Y position
		//	loop through the nodes and update their Y coordinates
		//	remove and re-create the sphere and line nodes
		if constrainSwitch.isOn {
			let yAvg = nodes.average(\.position.y)
			
			sceneView.scene.rootNode.childNodes.forEach { n in
				n.removeFromParentNode()
			}
			var prevNode: SCNNode!
			nodes.forEach { n in
				n.position.y = yAvg
				sceneView.scene.rootNode.addChildNode(n)
				if prevNode != nil {
					let lineBetweenNodes = LineNode(from: prevNode.position, to: n.position, lineColor: UIColor.systemBlue)
					sceneView.scene.rootNode.addChildNode(lineBetweenNodes)
				}
				prevNode = n
			}
			if let fn = nodes.first {
				let lineBetweenNodes = LineNode(from: prevNode.position, to: fn.position, lineColor: UIColor.systemBlue)
				sceneView.scene.rootNode.addChildNode(lineBetweenNodes)
			}
		}
		
		let path = UIBezierPath()
		
		let xOff = nodes[0].position.x
		let zOff = nodes[0].position.z
		
		// Iterate through the sphere nodes array
		for (index, nodes) in nodes.enumerated() {
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
		
		let shape = SCNShape(path: path, extrusionDepth: 0.001)
		
		shape.materials = [orangeMaterial, grassMat, cyanMaterial]

		shapeNode = SCNNode(geometry: shape)
		
		if let fNode = nodes.first {
			shapeNode.position = fNode.position
		}
		
		sceneView.scene.rootNode.addChildNode(shapeNode)
		
		self.r = 0.0
		if animSwitch.isOn {
			DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
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

	
	
	
	func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
		DispatchQueue.main.async { [self] in
			// get current hit position
			// and check if start-node is available
			if isEditingEnabled {
				
				guard let currentPosition = self.doHitTestOnExistingPlanes(),
					  let start = self.startingNode else {
					return
					
				}
				self.lineNode?.removeFromParentNode()
				self.lineNode = LineNode(from: start.position, to: currentPosition, lineColor: UIColor.systemBlue)
				self.sceneView.scene.rootNode.addChildNode(self.lineNode!)
			}
			else {
				self.lineNode?.removeFromParentNode()
				
			}
			
			
		}
	}
	
	func doHitTestOnExistingPlanes() -> SCNVector3? {
		
		let screenPoint = CGPoint(x: sceneView.bounds.midX, y: sceneView.bounds.midY)
		guard let raycastQuery = sceneView.raycastQuery(from: screenPoint, allowing: .estimatedPlane, alignment: .any) else {return nil }
		
		let raycastResults = sceneView.session.raycast(raycastQuery)
		
		guard let firstResult = raycastResults.first  else {  return nil }
		// get vector from transform
		let hitPos = SCNVector3.positionFrom(matrix: firstResult.worldTransform)
		return hitPos
		
		
		
	}
	
}
