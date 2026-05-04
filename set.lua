local ecnet2 = require "ecnet2"
    local random = require "ccryptolib.random"
    random.initWithTiming()
    ecnet2.open("top")
    local id = ecnet2.Identity("/.ecnet2")
    local protocal = id:Protocol {
    name = "set hight",
    -- Objects must be serialized before they are sent over.
    serialize = textutils.serialize,
    deserialize = textutils.unserialize,
  }
  server="o4lIZ0lLc955aNJSHz59UnDxxSqWrmbtXniuITeHqTo="
  local connection = protocal:connect(server, "top")
  connection:receive()
  connection:send({password="pass",hight=98})