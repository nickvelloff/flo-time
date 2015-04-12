noflo = require 'noflo'

unless noflo.isBrowser()
  chai = require 'chai' unless chai
  Client = require '../components/Client.coffee'
else
  Client = require 'twilio/components/Client.js'

describe 'Client component', ->
  c = null
  ins = null
  out = null

  unless process.env?
    return console.log '*** NOTE: testing only works in Node.js'

  beforeEach ->
    c = Client.getComponent()
    c.inPorts.account.attach noflo.internalSocket.createSocket()
    c.inPorts.token.attach noflo.internalSocket.createSocket()
    c.outPorts.out.attach noflo.internalSocket.createSocket()

    unless process.env.TWILIO_ACCOUNT_ID
      throw new Error 'Please set your test account SID to envrionment variable TWILIO_ACCOUNT_ID'
    unless process.env.TWILIO_AUTH_TOKEN
      throw new Error 'Please set your test auth token to envrionment variable TWILIO_AUTH_TOKEN'

  describe 'when instantiated', ->
    it 'should have input ports', ->
      chai.expect(c.inPorts.account).to.be.an 'object'
      chai.expect(c.inPorts.token).to.be.an 'object'

    it 'should have an output port', ->
      chai.expect(c.outPorts.out).to.be.an 'object'

  describe 'twilio client', ->
    it 'creates a twilio client object', (done) ->
      account = c.inPorts.account
      token = c.inPorts.token

      c.outPorts.out.on 'data', (client) ->
        chai.expect(client.accountSid).to.equal process.env.TWILIO_ACCOUNT_ID
        chai.expect(client.authToken).to.equal process.env.TWILIO_AUTH_TOKEN
        chai.expect(client.host).to.equal 'api.twilio.com'
      c.outPorts.out.on 'disconnect', ->
        done()

      account.connect()
      account.send process.env.TWILIO_ACCOUNT_ID
      account.disconnect()
      token.connect()
      token.send process.env.TWILIO_AUTH_TOKEN
      token.disconnect()
      
