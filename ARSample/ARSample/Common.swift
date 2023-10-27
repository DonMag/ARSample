//
//  CommonClasses.swift
//  ARSample
//
//  Created by Don Mag on 10/26/23.
//

import UIKit
import ARKit

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

extension Sequence  {
	func sum<T: AdditiveArithmetic>(_ predicate: (Element) -> T) -> T {
		reduce(.zero) { $0 + predicate($1) }
	}
}
extension Collection {
	func average<T: BinaryInteger>(_ predicate: (Element) -> T) -> T {
		sum(predicate) / T(count)
	}
	func average<T: BinaryInteger, F: BinaryFloatingPoint>(_ predicate: (Element) -> T) -> F {
		F(sum(predicate)) / F(count)
	}
	func average<T: BinaryFloatingPoint>(_ predicate: (Element) -> T) -> T {
		sum(predicate) / T(count)
	}
	func average(_ predicate: (Element) -> Decimal) -> Decimal {
		sum(predicate) / Decimal(count)
	}
}
