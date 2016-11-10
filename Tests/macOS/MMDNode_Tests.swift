//
//  MMDNode_Tests.swift
//  MMDSceneKit
//
//  Created by magicien on 7/11/16.
//  Copyright © 2016 DarkHorse. All rights reserved.
//

import XCTest

class MMDNode_Tests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let node = MMDNode()
        let quat = SCNVector4()
        let rotate = SCNVector4()
        
        rotate.x = 1
        rotate.y = 2
        rotate.z = 3
        rotate.w = 4
        
        quat = node.rotateToQuat(rotate)
        
        print(quat)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }

}
