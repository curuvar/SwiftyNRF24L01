//
// Copyright (c) 2021 Craig Altenburg
//
// This code licensed under the GNU GENERAL PUBLIC LICENSE Version 3
//
// See the accompanying LICENSE file for the terms of this license or
// read them at: https://www.gnu.org/licenses/gpl.html
//
// This code is based, in part, on C code Copyright (c) 2014 Antoine Leclair
// which was licensed under The MIT License which had the following terms:
//
//        Permission is hereby granted, free of charge, to any
//        person obtaining a copy of this software and associated
//        documentation files (the "Software"), to deal in the
//        Software without restriction, including without limitation
//        the rights to use, copy, modify, merge, publish,
//        distribute, sublicense, and/or sell copies of the Software,
//        and to permit persons to whom the Software is furnished to
//        do so, subject to the following conditions:
//
//        The above copyright notice and this permission notice shall
//        be included in all copies or substantial portions of the
//        Software.
//
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import Foundation
import SwiftyGPIO

// =============================================================================
//  NRF24L01
// =============================================================================
/// Support the nRF24L01 radio chip.

public class NRF24L01
{
  // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  //  Address
  // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  /// This struct holds an end point address.

  public struct Address
  {
    public  let rawValue : [UInt8]

    // -------------------------------------------------------------------------
    //  Initializers
    // -------------------------------------------------------------------------
    /// Create an Address based on five data bytes.

    public init( _ a0 : UInt8, _ a1 : UInt8, _ a2 : UInt8, _ a3 : UInt8, _ a4 : UInt8 )
    {
      rawValue = [ a0, a1, a2, a3, a4 ]
    }

    // -------------------------------------------------------------------------
    /// Create an Address based on an array of data bytes.

    public init?( rawValue: [UInt8] )
    {
      guard rawValue.count == 5 else { return nil }

      self.rawValue = rawValue
    }
  }


  // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  //  Message
  // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

  public struct Message
  {
    public let pipe : Pipe
    public let data : [UInt8]
  }

  // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  //  Pipe
  // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

  public enum Pipe : UInt8
  {
  case p0 = 0, p1, p2, p3, p4, p5

    public var rxAddrReg : Register { Register( rawValue: self.rawValue + 0x0A )! }
    public var rxPwReg   : Register { Register( rawValue: self.rawValue + 0x11 )! }
  }

  // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  //  TXStatus
  // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

  public enum TXStatus { case complete, timeout, inactive }

  // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  //  Command
  // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  //
  // - Note: Do not use the R_REGISTER and W_REGISTER commands with the
  //         send and receive command functions as the register cannot
  //         be specified.  Use the read and write register functions
  //         instead
  //
  public enum Command : UInt8
  {
  //    Command             value    bits       Data Length
  case R_REGISTER         = 0x00 // 000A AAAA     1 to  5
  case W_REGISTER         = 0x20 // 001A AAAA     1 to  5
  case R_RX_PAYLOAD       = 0x61 // 0110 0001     1 to 32
  case W_TX_PAYLOAD       = 0xA0 // 1010 0000     1 to 32
  case FLUSH_TX           = 0xE1 // 1110 0001      none
  case FLUSH_RX           = 0xE2 // 1110 0010      none
  case REUSE_TX_PL        = 0xE3 // 1110 0011      none
  case ACTIVATE           = 0x50 // 0101 0000        1  (must be 0x73)
  case R_RX_PL_WID        = 0x60 // 0110 0000        1
  case W_ACK_PAYLOAD_0    = 0xA8 // 1010 1000     1 to 32
  case W_ACK_PAYLOAD_1    = 0xA9 // 1010 1001     1 to 32
  case W_ACK_PAYLOAD_2    = 0xAA // 1010 1010     1 to 32
  case W_ACK_PAYLOAD_3    = 0xAB // 1010 1011     1 to 32
  case W_ACK_PAYLOAD_4    = 0xAC // 1010 1100     1 to 32
  case W_ACK_PAYLOAD_5    = 0xAD // 1010 1101     1 to 32
  case W_TX_PAYLOAD_NOACK = 0xB0 // 1011 0000     1 to 32
  case NOP                = 0xFF // 1111 1111      none
  }

  // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  //  Register
  // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

  public enum Register : UInt8
  {
  case CONFIG              = 0x00
  case EN_AA               = 0x01
  case EN_RXADDR           = 0x02
  case SETUP_AW            = 0x03
  case SETUP_RETR          = 0x04
  case RF_CH               = 0x05
  case RF_SETUP            = 0x06
  case STATUS              = 0x07
  case OBSERVE_TX          = 0x08
  case RPD                 = 0x09
  case RX_ADDR_P0          = 0x0A
  case RX_ADDR_P1          = 0x0B
  case RX_ADDR_P2          = 0x0C
  case RX_ADDR_P3          = 0x0D
  case RX_ADDR_P4          = 0x0E
  case RX_ADDR_P5          = 0x0F
  case TX_ADDR             = 0x10
  case RX_PW_P0            = 0x11
  case RX_PW_P1            = 0x12
  case RX_PW_P2            = 0x13
  case RX_PW_P3            = 0x14
  case RX_PW_P4            = 0x15
  case RX_PW_P5            = 0x16
  case FIFO_STATUS         = 0x17
  case DYNPD               = 0x1C
  case FEATURE             = 0x1D
  }

  // ---------------------------------------------------------------------------
  // Bit Masks
  // ---------------------------------------------------------------------------

  // --- CONFIG ---
  public let  MASK_RX_DR     : UInt8 = 0b0100_0000
  public let  MASK_TX_DS     : UInt8 = 0b0010_0000
  public let  MASK_MAX_RT    : UInt8 = 0b0001_0000
  public let  EN_CRC         : UInt8 = 0b0000_1000
  public let  CRCO           : UInt8 = 0b0000_0100
  public let  PWR_UP         : UInt8 = 0b0000_0010
  public let  PRIM_RX        : UInt8 = 0b0000_0001

  // --- SETUP_AW ---
  public let  AW             : UInt8 = 0b0000_0011

  // --- SETUP_RETR ---
  public let  ARD            : UInt8 = 0b1111_0000
  public let  ARC            : UInt8 = 0b0000_1111

  // --- RF_SETUP ---
  public let  PLL_LOCK       : UInt8 = 0b0001_0000
  public let  RF_DR          : UInt8 = 0b0000_1000
  public let  RF_PWR         : UInt8 = 0b0000_0110
  public let  LNA_HCURR      : UInt8 = 0b0000_0001;


  // --- STATUS ---
  public let  RX_DR          : UInt8 = 0b0100_0000
  public let  TX_DS          : UInt8 = 0b0010_0000
  public let  MAX_RT         : UInt8 = 0b0001_0000
  public let  RX_P_NO_MASK   : UInt8 = 0b0000_1110
  public let  STATUS_TX_FUL  : UInt8 = 0b0000_0001

  // --- OBSERVE_TX ---
  public let  PLOS_CNT       : UInt8 = 0b1111_0000
  public let  ARC_CNT        : UInt8 = 0b0000_1111

  // ---FIFO_STATUS ---
  public let  TX_REUSE       : UInt8 = 0b0100_0000
  public let  FIFO_TX_FULL   : UInt8 = 0b0010_0000
  public let  TX_EMPTY       : UInt8 = 0b0001_0000
  public let  RX_FULL        : UInt8 = 0b0000_0010
  public let  RX_EMPTY       : UInt8 = 0b0000_0001

  // --- FEATURE ---
  public let  EN_DPL         : UInt8 = 0b0000_0100
  public let  EN_ACK_PAY     : UInt8 = 0b0000_0010
  public let  EN_DYN_ACK     : UInt8 = 0b0000_0001


  // ---------------------------------------------------------------------------
  //  properties
  // ---------------------------------------------------------------------------

  public private(set) var status : UInt8 = 0

  public let csn    : GPIO // Slave Select
  public let ce     : GPIO // Chip Enable
  public let irq    : GPIO // Interrupt Request

  let spi    = SysFSSPI( spiId: "0.1" )

  // ---------------------------------------------------------------------------
  //  initializer
  // ---------------------------------------------------------------------------
  /// Initialize the radio chip with the following properties:
  ///  - Enable CRC
  ///  - Use 2 byte CRC
  ///  - Power up to Standby-| mode
  ///  - Auto acknowledge set on all pipes.
  ///  - Dynamic payoad length on all pipes.
  ///  - Disable all data pipes
  ///
  ///  If not change by the user the following default
  ///  parameters are in effece.
  ///
  ///  - Use 5 byte address
  ///  - Auto retransmit delay 250uS
  ///  - Auto retransmit count 3
  ///  - RF Channel 2
  ///  - No payload with ACK


  public init( csn : GPIO, ce : GPIO, irq : GPIO )
  {
    self.csn = csn
    self.ce  = ce
    self.irq = irq

    csn.direction = .OUT
    csn.value = 1

    ce.direction = .OUT
    ce.value = 0

    irq.direction = .IN

    send( command: .FLUSH_RX )

    send( command: .FLUSH_TX )

    clearInterrupts()

    // Activate extra features

    send( command: .ACTIVATE, value: 0x73 )

    // Move radio to Standby-1 state (powered up)

    write( register: .CONFIG, value:  EN_CRC    // Enable CRC
                                    | CRCO      // Two byte CRC check
                                    | PWR_UP    // Chip is powered up
                                    | PRIM_RX ) // Chip is in receive mode

    // Give a short delay to allow the radio chip to power up.

    sleep( 1 )

    // Set a default channel

    write( register: .RF_CH, value: 0x02 );

    // Set address width 5

    write( register: .SETUP_AW, value: 0x03 );

    // Set 4 retries 1mS appart.

    write( register: .SETUP_RETR, value: 0x34 );

    // Set default RF parameters -  Air data rate: 2Mbps  output: 0dBm

    write( register: .RF_SETUP, value: 0x0F );

    // Enable auto acknowlegde on all pipes

    write( register: .EN_AA, value: 0x3F );

    // Enable dynamic payload on all pipes

    write( register: .DYNPD, value: 0x3F );

    // Enable dynamic payload (global)

    write( register: .FEATURE, value: EN_DPL );

    // Not listening on any pipe.

    write( register: .EN_RXADDR, value: 0 );

  }

  // -------------------------------------------------------------------------
  //  De-Initializers
  // -------------------------------------------------------------------------

  deinit
  {
    // Set the config back to its initial value.  We do this
    // to power off the radio chip.

    write( register: .CONFIG, value:  EN_CRC )  // Enable CRC
  }

  // ==== Functions to communicate with radio chip =============================

  // ---------------------------------------------------------------------------
  //  send (command only)
  // ---------------------------------------------------------------------------
  /// Send a command byte to the radio and receive the status.
  ///
  /// As a side effect the class's status property is update with
  /// the status value read from the radio chip.
  ///
  /// - Parameter command: The command byte to sent.
  ///
  /// - Returns: The status byte received when the command byte is sent.

  @discardableResult
  public func send( command : Command ) -> UInt8
  {
    csn.value = 0

    status = spi.sendDataAndRead( [ command.rawValue ] )[0]

    csn.value = 1

    return status
  }

  // ---------------------------------------------------------------------------
  //  send (command and single byte)
  // ---------------------------------------------------------------------------
  /// Send a command and one byte of data to the radio chip and
  /// receive the status.
  ///
  /// As a side effect the class's status property is update with
  /// the status value read from the radio chip.
  ///
  /// - Parameter command: The command byte to sent.
  /// - Parameter value:   The data byte to sent.
  ///
  /// - Returns: The status byte received when the command byte is sent.


  @discardableResult
  public func send( command : Command, value: UInt8 ) -> UInt8
  {
    csn.value = 0

    status = spi.sendDataAndRead( [ command.rawValue, value ] )[0]

    csn.value = 1

    return status
  }

  // ---------------------------------------------------------------------------
  //  send (command and multiple bytes)
  // ---------------------------------------------------------------------------
  /// Send a command and one byte of data to the radio chip and
  /// receive the status.
  ///
  /// As a side effect the class's status property is update with
  /// the status value read from the radio chip.
  ///
  /// - Parameter command: The command byte to sent.
  /// - Parameter data:    The data to sent.
  ///
  /// - Returns: The status byte received when the command byte is sent.

  @discardableResult
  public func send( command : Command, data: [UInt8] ) -> UInt8
  {
    csn.value = 0

    status = spi.sendDataAndRead( [ command.rawValue ] )[0]

    spi.sendData( data )

    csn.value = 1

    return status
  }

  // ---------------------------------------------------------------------------
  //  receive (single byte)
  // ---------------------------------------------------------------------------
  /// Send a command (and receive the status) then receive one byte of data
  /// from the radio chip
  ///
  /// As a side effect the class's status property is update with
  /// the status value read from the radio chip.
  ///
  /// - Parameter command: The command byte to sent.
  ///
  /// - Returns: The data byte received from the radio chip.

  public func receive( command : Command ) -> UInt8
  {
    csn.value = 0

    let result = spi.sendDataAndRead( [ command.rawValue, 0 ] )

    status = result[0]

    csn.value = 1

    return result[1]
  }

  // ---------------------------------------------------------------------------
  //  receive (multi-byte)
  // ---------------------------------------------------------------------------
  /// Send a command (and receive the status) then receive multiple bytes of data
  /// from the radio chip
  ///
  /// As a side effect the class's status property is update with
  /// the status value read from the radio chip.
  ///
  /// - Parameter command: The command byte to sent.
  /// - Parameter length: The number of bytes of data to read.
  ///
  /// - Returns: The data received from the radio chip.

  public func receive( command : Command, length: Int ) -> [UInt8]
  {
    csn.value = 0

    status = spi.sendDataAndRead( [ command.rawValue ] ) [0]

    let result = spi.sendDataAndRead( [UInt8]( repeating: 0, count: length ) )

    csn.value = 1

    return result
  }

  // ---------------------------------------------------------------------------
  //  write (single byte)
  // ---------------------------------------------------------------------------
  /// Write one byte to a register in the radio chip and
  /// receive the status.
  ///
  /// As a side effect the class's status property is update with
  /// the status value read from the radio chip.
  ///
  /// - Parameter register: The register to update.
  /// - Parameter value:   The data byte to write.
  ///
  /// - Returns: The status byte received when the first byte is sent.

  @discardableResult
  public func write( register : Register, value: UInt8 ) -> UInt8
  {
    csn.value = 0

    let command = Command.W_REGISTER.rawValue | register.rawValue

    status = spi.sendDataAndRead( [ command, value ] )[0]

    csn.value = 1

    return status
  }

  // ---------------------------------------------------------------------------
  //  write (multi-byte)
  // ---------------------------------------------------------------------------
  /// Write one byte to a register in the radio chip and
  /// receive the status.
  ///
  /// As a side effect the class's status property is update with
  /// the status value read from the radio chip.
  ///
  /// - Parameter register: The register to update.
  /// - Parameter data:     The data to sent.
  ///
  /// - Returns: The status byte received when the first byte is sent.

  @discardableResult
  public func write( register : Register, data: [UInt8] ) -> UInt8
  {
    csn.value = 0

    let command = Command.W_REGISTER.rawValue | register.rawValue

    status = spi.sendDataAndRead( [ command ] )[0]

    spi.sendData( data )

    csn.value = 1

    return status
  }

  // ---------------------------------------------------------------------------
  //  read (single byte)
  // ---------------------------------------------------------------------------
  /// Read one byte from a register in the radio chip.
  ///
  /// As a side effect the class's status property is update with
  /// the status value read from the radio chip.
  ///
  /// - Parameter register: The register to read.
  ///
  /// - Returns: The data byte read from the selected register.

  public func read( register : Register ) -> UInt8
  {
    csn.value = 0

    let command = Command.R_REGISTER.rawValue | register.rawValue

    let result = spi.sendDataAndRead( [ command, 0 ] )

    status = result[0]

    csn.value = 1

    return result[1]
  }

  // ---------------------------------------------------------------------------
  //  read (multi-byte)
  // ---------------------------------------------------------------------------
  /// Read bytes from a register in the radio chip.
  ///
  /// As a side effect the class's status property is update with
  /// the status value read from the radio chip.
  ///
  /// - Parameter register: The register to read.
  /// - Parameter length:   The amount of data to read.
  ///
  /// - Returns: The data read from the selected register.

  public func read( register : Register, length : Int ) -> [UInt8]
  {
    csn.value = 0

    let command = Command.R_REGISTER.rawValue | register.rawValue

    status = spi.sendDataAndRead( [ command ] )[0]

    let result = spi.sendDataAndRead( [UInt8]( repeating: 0, count: length ) )

    csn.value = 1

    return result
  }

  // ---------------------------------------------------------------------------
  //  listen
  // ---------------------------------------------------------------------------
  ///  Configure the indicated pipe to listen for messanges sent to the
  ///  supplied address.
  ///
  /// - Parameter pipe: the pipe to receive on
  /// - Parameter address: the address to listen to

  public func listen( pipe : Pipe, address : Address )
  {
    write( register: pipe.rxAddrReg, data: address.rawValue )

    let currentPipes = read( register: .EN_RXADDR ) | (1 << pipe.rawValue)

    write( register: .EN_RXADDR, value: currentPipes )

    ce.value = 1
  }

  // ---------------------------------------------------------------------------
  //  haveReceivedData
  // ---------------------------------------------------------------------------
  /// Check to see if data is available to read.  Property returns true if
  /// data is available.
  ///
  /// As a side effect the class's status property is update with
  /// the status value read from the radio chip.

  public var haveReceivedData : Bool
  {
    ce.value = 0

    send( command: .NOP ) // Update status

    return (status & RX_DR) != 0
  }

  // -----------------------------------------------------------------------------
  //  receivedMessage
  // -----------------------------------------------------------------------------
  ///  Fetch a received message.
  ///
  /// - Returns: A Message structure continaing the data and the pipe
  ///            over which the data was received; or nil if no data is
  ///            available.

  public func receivedMessage() -> Message?
  {
    guard haveReceivedData else { return nil }

    clearReceiveInterrupt();

    let pipeNumber = (status & RX_P_NO_MASK) >> 1

    guard pipeNumber <= 5 else { return nil }

    let msgLength = Int( receive( command: .R_RX_PL_WID ) );

    return Message( pipe: Pipe( rawValue: pipeNumber )!,
                    data: receive( command: .R_RX_PAYLOAD,
                                   length:  msgLength ) )
  }

  // -----------------------------------------------------------------------------
  //  transmit
  // -----------------------------------------------------------------------------
  //  Start a transmission sending the message to the given address.
  //
  //  - Returns false if the length of the message exceeds 32 bytes.

  @discardableResult
  public func transmit( address: Address, message: [UInt8] ) -> Bool
  {
    guard message.count <= 32 else { return false }

    clearTransmitInterrupts()

    write( register: .TX_ADDR,    data: address.rawValue )
    write( register: .RX_ADDR_P0, data: address.rawValue )

    send( command: .W_TX_PAYLOAD, data: message )

    let currentPipes = read( register: .EN_RXADDR ) | 1
    write( register: .EN_RXADDR, value: currentPipes )

    let config = read( register: .CONFIG ) & ~PRIM_RX
    write( register: .CONFIG, value: config )

    ce.value = 1
    usleep( 20 )
    ce.value = 0

    return true
  }

  // -----------------------------------------------------------------------------
  //  transmitStatus
  // -----------------------------------------------------------------------------
  //  This should be called as a result of a radio interrupt following a
  //  transmit request.
  //
  //  It returns the status of the transmission.

  public func transmitStatus() -> TXStatus
  {
    send( command: .NOP )  // Update status

    let retval : TXStatus;

    if      ((status & TX_DS)  != 0) { retval = .complete }
    else if ((status & MAX_RT) != 0) { retval = .timeout }
    else                             { retval = .inactive }

    clearTransmitInterrupts()

    let currentPipes = read( register: .EN_RXADDR ) & ~1
    write( register: .EN_RXADDR, value: currentPipes )

    let config = read( register: .CONFIG ) | PRIM_RX

    write( register: .CONFIG, value: config )

    return retval
  }

  // -----------------------------------------------------------------------------
  //  flushTransmitBuffer
  // -----------------------------------------------------------------------------
  //  This clears any pending transmission for the transmit buffer.

  public func flushTransmitBuffer()
  {
    send( command: .FLUSH_TX )
  }

  // -----------------------------------------------------------------------------
  //  retryTransmit
  // -----------------------------------------------------------------------------
  //  This retrys the last transmission if the transmitStatus function indicated
  //  a timeout or failed transmission.

  public func retryTransmit()
  {
    // XXX not sure it works this way, never tested

    let config = read( register: .CONFIG ) & ~PRIM_RX

    write( register: .CONFIG, value: config )

    ce.value = 1
  }

  // -----------------------------------------------------------------------------
  //  clearInterrupts
  // -----------------------------------------------------------------------------
  //  This clears all interrupt flags.

  public func clearInterrupts()
  {
    write( register: .STATUS, value: RX_DR | TX_DS | MAX_RT )
  }

  // -----------------------------------------------------------------------------
  //  clearTransmitInterrupts
  // -----------------------------------------------------------------------------
  //  This clears all transmit interrupt flags.

  public func clearTransmitInterrupts()
  {
    write( register: .STATUS, value: TX_DS | MAX_RT )
  }

  // -----------------------------------------------------------------------------
  //  clearReceiveInterrupt
  // -----------------------------------------------------------------------------
  //  This clears the receive interrupt flag.

  public func clearReceiveInterrupt()
  {
    write( register: .STATUS, value: RX_DR )
  }

}

