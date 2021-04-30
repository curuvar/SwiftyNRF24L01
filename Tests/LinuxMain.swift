import XCTest

import SwiftyNRF24L01Tests

var tests = [XCTestCaseEntry]()

tests += nRF24L01Tests.allTests()

XCTMain( tests )
