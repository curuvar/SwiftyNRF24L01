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


import SwiftyGPIO
// =============================================================================
//  NRF24L01
// =============================================================================
/// Support the nRF24L01 radio chip.

class NRF24L01
{
  // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  //  Address
  // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  /// This struct holds an end point address.

  struct Address
  {
    let rawValue : [UInt8]

    // -------------------------------------------------------------------------
    //  Initializers
    // -------------------------------------------------------------------------
    /// Create an Address based on five data bytes.

    init( _ a0 : UInt8, _ a1 : UInt8, _ a2 : UInt8, _ a3 : UInt8, _ a4 : UInt8 )
    {
      rawValue = [ a0, a1, a2, a3, a4 ]
    }

    // -------------------------------------------------------------------------
    //  Initializers
    // -------------------------------------------------------------------------
    /// Create an Address based on one data byte.

    init( _ a0 : UInt8 )
    {
      rawValue = [ a0 ]
    }

    // -------------------------------------------------------------------------
    /// Create an Address based on an array of data bytes.

    init?( rawValue: [UInt8] )
    {
      guard rawValue.count == 5 else { return nil }

      self.rawValue = rawValue
    }
  }

  // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  //  Message
  // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

  struct Message
  {
    let pipe : Pipe
    let data : [UInt8]
  }

  // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  //  Pipe
  // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

  enum Pipe : UInt8
  {
  case p0 = 0, p1, p2, p3, p4, p5

    var rxAddrReg : Register { Register( rawValue: self.rawValue + 0x0A )! }
    var rxPwReg   : Register { Register( rawValue: self.rawValue + 0x11 )! }
  }

  // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  //  TXStatus
  // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

  enum TXStatus { case complete, timeout, inactive }

  // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  //  Command
  // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

  enum Command : UInt8
  {
  case R_REGISTER         = 0x00 // 000A AAAA
  case W_REGISTER         = 0x20 // 001A AAAA
  case R_RX_PAYLOAD       = 0x61 // 0110 0001
  case W_TX_PAYLOAD       = 0xA0 // 1010 0000
  case FLUSH_TX           = 0xE1 // 1110 0001
  case FLUSH_RX           = 0xE2 // 1110 0010
  case REUSE_TX_PL        = 0xE3 // 1110 0011
  case R_RX_PL_WID        = 0x60 // 0110 0000
  case W_ACK_PAYLOAD      = 0xA8 // 1010 1PPP
  case W_TX_PAYLOAD_NOACK = 0xB0 // 1011 0000
  case NOP                = 0xFF // 1111 1111
  }

  // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  //  Register
  // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

  enum Register : UInt8
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
  let  MASK_RX_DR     : UInt8 = 0b0100_0000
  let  MASK_TX_DS     : UInt8 = 0b0010_0000
  let  MASK_MAX_RT    : UInt8 = 0b0001_0000
  let  EN_CRC         : UInt8 = 0b0000_1000
  let  CRCO           : UInt8 = 0b0000_0100
  let  PWR_UP         : UInt8 = 0b0000_0010
  let  PRIM_RX        : UInt8 = 0b0000_0001

  // --- SETUP_AW ---
  let  AW             : UInt8 = 0b0000_0001

  // --- SETUP_RETR ---
  let  ARD            : UInt8 = 0b0001_0000
  let  ARC            : UInt8 = 0b0000_0001


  // --- RF_SETUP ---
  let  CONT_WAVE      : UInt8 = 0b1000_0000
  let  RF_DR_LOW      : UInt8 = 0b0010_0000
  let  PLL_LOCK       : UInt8 = 0b0001_0000
  let  RF_DR_HIGH     : UInt8 = 0b0000_1000
  let  RF_PWR         : UInt8 = 0b0000_0010

  // --- STATUS ---
  let  RX_DR          : UInt8 = 0b0100_0000
  let  TX_DS          : UInt8 = 0b0010_0000
  let  MAX_RT         : UInt8 = 0b0001_0000
  let  RX_P_NO_MASK   : UInt8 = 0b0000_1110
  let  STATUS_TX_FUL  : UInt8 = 0b0000_0001

  // --- OBSERVE_TX ---
  let  PLOS_CNT       : UInt8 = 0b0001_0000
  let  ARC_CNT        : UInt8 = 0b0000_0001

  // ---FIFO_STATUS ---
  let  TX_REUSE       : UInt8 = 0b0100_0000
  let  FIFO_TX_FULL   : UInt8 = 0b0010_0000
  let  TX_EMPTY       : UInt8 = 0b0001_0000
  let  RX_FULL        : UInt8 = 0b0000_0010
  let  RX_EMPTY       : UInt8 = 0b0000_0001

  // --- FEATURE ---
  let  EN_DPL         : UInt8 = 0b0000_0100
  let  EN_ACK_PAY     : UInt8 = 0b0000_0010
  let  EN_DYN_ACK     : UInt8 = 0b0000_0001


  // ---------------------------------------------------------------------------
  //  properties
  // ---------------------------------------------------------------------------

  var status : UInt8 = 0

  let csn    : GPIO // Slave Select
  let ce     : GPIO // Chip Enable
  let irq    : GPIO // Interrupt Request

  let spi    = SysFSSPI( spiId: "0.1" )

  // ---------------------------------------------------------------------------
  //  initializer
  // ---------------------------------------------------------------------------

  init( csn : GPIO, ce : GPIO, irq : GPIO )
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

    // Move radio to Standby-1 state (powered up)

    write( register: .CONFIG, value:  EN_CRC    // Enable CRC
                                    | CRCO      // Two byte CRC check
                                    | PWR_UP    // Chip is powered up
                                    | PRIM_RX ) // Chip is in receive mode

    // Enable auto acknowlegde on all pipes

    write( register: .EN_AA, value: 0x3F );

    // Enable dynamic payload on all pipes

    write( register: .DYNPD, value: 0x3F );

    // Enable dynamic payload (global)

    write( register: .FEATURE, value: EN_DPL );

    // Disable all receive addresses except p0

    write( register: .EN_RXADDR, value: 1 );

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
  func send( command : Command ) -> UInt8
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
  func send( command : Command, value: UInt8 ) -> UInt8
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
  func send( command : Command, data: [UInt8] ) -> UInt8
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

  func receive( command : Command ) -> UInt8
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

  func receive( command : Command, length: Int ) -> [UInt8]
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
  func write( register : Register, value: UInt8 ) -> UInt8
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
  func write( register : Register, data: [UInt8] ) -> UInt8
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

  func read( register : Register ) -> UInt8
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

  func read( register : Register, length : Int ) -> [UInt8]
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

  func listen( pipe : Pipe, address : Address )
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

  var haveReceivedData : Bool
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

  func receivedMessage() -> Message?
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

  func transmit( address: Address, message: [UInt8] )
  {
    clearTransmitInterrupts()

    write( register: .TX_ADDR,    data: address.rawValue )
    write( register: .RX_ADDR_P0, data: address.rawValue )

    send( command: .W_TX_PAYLOAD, data: message )

    let config = read( register: .CONFIG ) & ~PRIM_RX

    write( register: .CONFIG, value: config )

    ce.value = 1
  }

  // -----------------------------------------------------------------------------
  //  transmitStatus
  // -----------------------------------------------------------------------------
  //  This should be called as a result of a radio interrupt following a
  //  transmit request.
  //
  //  It returns the status of the transmission.

  func transmitStatus() -> TXStatus
  {
    ce.value = 0

    send( command: .NOP )  // Update status

    let retval : TXStatus;

    if      ((status & TX_DS)  != 0) { retval = .complete }
    else if ((status & MAX_RT) != 0) { retval = .timeout }
    else                             { retval = .inactive }

    clearTransmitInterrupts()

    let config = read( register: .CONFIG ) | PRIM_RX

    write( register: .CONFIG, value: config )

    return retval
  }

  // -----------------------------------------------------------------------------
  //  flushTransmitBuffer
  // -----------------------------------------------------------------------------
  //  This clears any pending transmission for the transmit buffer.

  func flushTransmitBuffer()
  {
    send( command: .FLUSH_TX )
  }

  // -----------------------------------------------------------------------------
  //  retryTransmit
  // -----------------------------------------------------------------------------
  //  This retrys the last transmission if the transmitStatus function indicated
  //  a timeout or failed transmission.

  func retryTransmit()
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

  func clearInterrupts()
  {
    write( register: .STATUS, value: RX_DR | TX_DS | MAX_RT )
  }

  // -----------------------------------------------------------------------------
  //  clearTransmitInterrupts
  // -----------------------------------------------------------------------------
  //  This clears all transmit interrupt flags.

  func clearTransmitInterrupts()
  {
    write( register: .STATUS, value: TX_DS | MAX_RT )
  }

  // -----------------------------------------------------------------------------
  //  clearReceiveInterrupt
  // -----------------------------------------------------------------------------
  //  This clears the receive interrupt flag.

  func clearReceiveInterrupt()
  {
    write( register: .STATUS, value: RX_DR )
  }

}

