import XCTest
import SwiftyGPIO

@testable import  SwiftyNRF24L01

final class SwiftyNRF24L01Tests: XCTestCase
{
  let gpios = SwiftyGPIO.GPIOs( for: .RaspberryPi4 )

  func radioInit()
  {
    let radio = NRF24L01( csn : gpios[.P0]!,
                          ce  : gpios[.P6]!,
                          irq : gpios[.P5]! )

    XCTAssertEqual( radio.send( command: .NOP ),     0b0000_1110 )

    XCTAssertEqual( radio.read( register: .CONFIG ), 0b0000_1111 )

    gpios[.P5]?.onRaising
          {
            pin in print( "onRaising triggered for \(pin) " )
          }

    gpios[.P5]?.onFalling
          { pin in
            print( "onFalling triggered for \(pin) " )
          }

  }

  func radioReceiveSetup()
  {
    let radio = NRF24L01( csn : gpios[.P0]!,
                          ce  : gpios[.P6]!,
                          irq : gpios[.P5]! )

    let testAddress = NRF24L01.Address( 0x31, 0x14, 0x15, 0x26, 0x53 )
    let pipe        : NRF24L01.Pipe = .p1

    XCTAssertEqual( testAddress.rawValue, [ 0x31, 0x14, 0x15, 0x26, 0x53 ] )

    radio.listen( pipe: pipe, address: testAddress )

    XCTAssertEqual( radio.status, 0b0000_1110 )

    XCTAssertEqual( radio.read( register: .EN_RXADDR ), (1 << pipe.rawValue) )

    XCTAssertEqual( radio.read( register: .RX_ADDR_P1, length: 5 ), testAddress.rawValue )
  }

  func radioTransmitTest()
  {
    let radio = NRF24L01( csn : gpios[.P0]!,
                          ce  : gpios[.P6]!,
                          irq : gpios[.P5]! )

    let testAddress = NRF24L01.Address( 0x31, 0x14, 0x15, 0x26, 0x53 )

    XCTAssertEqual( radio.transmitStatus(), NRF24L01.TXStatus.inactive )

    radio.transmit( address: testAddress, message: [0,1,2,3,4,5,6,7,8,9,10] )

    XCTAssertEqual( radio.read( register: .CONFIG ), 0b0000_1110 )

    XCTAssertEqual( radio.read( register: .TX_ADDR,    length: 5 ), testAddress.rawValue )
    XCTAssertEqual( radio.read( register: .RX_ADDR_P0, length: 5 ), testAddress.rawValue )

    // Busy wait for TS_DS or MAX_RT

    while (radio.send( command: .NOP ) & (radio.TX_DS | radio.MAX_RT)) == 0 {}

    XCTAssertEqual( radio.transmitStatus(), NRF24L01.TXStatus.timeout )

    radio.clearTransmitInterrupts()

    XCTAssertEqual( radio.transmitStatus(), NRF24L01.TXStatus.inactive )

    sleep( 10 )
  }

  static var allTests =
    [
      ( "radioInit", radioInit ),
      ( "radioTransmitTest", radioTransmitTest ),
      ( "radioReceiveSetup", radioReceiveSetup ),
    ]
}

