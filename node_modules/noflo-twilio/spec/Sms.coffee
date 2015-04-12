noflo = require 'noflo'
twilio = require 'twilio'

unless noflo.isBrowser()
  chai = require 'chai' unless chai
  Sms = require '../components/Sms.coffee'
else
  Sms = require 'twilio/components/Sms.js'

describe 'Sms component', ->
  c = null
  ins = null
  out = null
  client = null

  unless process.env?
    return console.log "*** NOTE: testing only works in Node.js"

  beforeEach ->
    c = Sms.getComponent()
    c.inPorts.client.attach noflo.internalSocket.createSocket()
    c.inPorts.send.attach noflo.internalSocket.createSocket()
    c.inPorts.receive.attach noflo.internalSocket.createSocket()
    c.outPorts.out.attach noflo.internalSocket.createSocket()

    unless process.env.TWILIO_ACCOUNT_ID
      throw new Error 'Please set your test account SID to envrionment variable TWILIO_ACCOUNT_ID'
    unless process.env.TWILIO_AUTH_TOKEN
      throw new Error 'Please set your test auth token to envrionment variable TWILIO_AUTH_TOKEN'

    client = twilio process.env.TWILIO_ACCOUNT_ID, process.env.TWILIO_AUTH_TOKEN

    cli = c.inPorts.client
    cli.connect()
    cli.send client
    cli.disconnect()

  describe 'when instantiated', ->
    it 'should have input ports', ->
      chai.expect(c.inPorts.client).to.be.an 'object'
      chai.expect(c.inPorts.send).to.be.an 'object'
      chai.expect(c.inPorts.receive).to.be.an 'object'

    it 'should have an output port', ->
      chai.expect(c.outPorts.out).to.be.an 'object'

  describe 'twilio client', ->
    it 'accepts a twilio client object', ->
      chai.expect(c.client).to.equal client
      chai.expect(client.accountSid).to.equal process.env.TWILIO_ACCOUNT_ID
      chai.expect(client.authToken).to.equal process.env.TWILIO_AUTH_TOKEN
      chai.expect(client.host).to.equal 'api.twilio.com'

  describe 'sending SMS messages', ->
    it 'sends an SMS message', (done) ->
      send = c.inPorts.send
      out = c.outPorts.out

      out.on 'data', (data) ->
        chai.expect(data.price).to.equal null
        chai.expect(data.from).to.equal '+15005550006'
        chai.expect(data.to).to.equal '+15005550006'
        chai.expect(data.body).to.equal 'test'
      out.on 'disconnect', ->
        done()

      send.connect()
      send.send
        from: '+15005550006'
        to: '+15005550006'
        body: 'test'
      send.disconnect()

    it 'sends an SMS message but an error is returned', (done) ->
      send = c.inPorts.send
      out = c.outPorts.out

      out.on 'data', (data) ->
        chai.expect(data.status).to.equal 400
        chai.expect(data.code).to.equal 21606
      out.on 'disconnect', ->
        done()

      send.connect()
      send.send
        from: '+15005550000'
        to: '+15005550006'
        body: 'test'
      send.disconnect()

    it 'sends multiple SMS messages', (done) ->
      send = c.inPorts.send
      out = c.outPorts.out
      count = 0

      out.on 'data', (data) ->
        chai.expect(data.price).to.equal null
      out.on 'disconnect', ->
        count++
        done() if count is 3

      send.connect()
      send.send
        from: '+15005550006'
        to: '+15005550006'
        body: 'a'
      send.send
        from: '+15005550006'
        to: '+15005550006'
        body: 'b'
      send.send
        from: '+15005550006'
        to: '+15005550006'
        body: 'c'
      send.disconnect()

  describe 'receiving SMS messages (which should get an error because of limited test credential capability', ->
    it 'receives an SMS message', (done) ->
      send = c.inPorts.send
      receive = c.inPorts.receive
      out = c.outPorts.out

      out.once 'data', (data) ->
        out.once 'data', (data) ->
          chai.expect(data.status).to.equal 403
          chai.expect(data.code).to.equal 20008
        out.once 'disconnect', (data) ->
          done()

        receive.connect()
        receive.send data.sid
        receive.disconnect()

      send.connect()
      send.send
        from: '+15005550006'
        to: '+15005550006'
        body: 'test'
      send.disconnect()

    it 'receives all stored SMS messages', ->
      send = c.inPorts.send
      receive = c.inPorts.receive
      out = c.outPorts.out

      out.on 'data', (data) ->
        chai.expect(data.status).to.equal 403
        chai.expect(data.code).to.equal 20008
      out.on 'disconnect', (data) ->
        done()

      receive.connect()
      receive.disconnect()
