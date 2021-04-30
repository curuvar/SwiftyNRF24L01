import XCTest

#if !canImport( ObjectiveC )

public func allTests() -> [XCTestCaseEntry]
{
  return [
           testCase( SwiftyNRF24L01Tests.allTests ),
         ]
}

#endif
