noflo = require 'noflo'
twilio = require 'twilio'

class Client extends noflo.Component
  constructor: ->
    @inPorts =
      account: new noflo.Port
      token: new noflo.Port
    @outPorts =
      out: new noflo.Port

    @inPorts.account.on 'data', (@account) =>
      @createClient()
    @inPorts.token.on 'data', (@token) =>
      @createClient()

  createClient: ->
    return unless @account? and @token?

    client = twilio @account, @token
    @outPorts.out.send client
    @outPorts.out.disconnect()

    delete @account
    delete @token

exports.getComponent = -> new Client
