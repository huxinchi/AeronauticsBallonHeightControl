 ecnet2 = require "ecnet2"
     random = require "ccryptolib.random"
    random.initWithTiming()
    ecnet2.open("top")
    id = ecnet2.Identity("/.ecnet2")
    protocal = id:Protocol {
    name = "set_hight",
    -- Objects must be serialized before they are sent over.
    serialize = textutils.serialize,
    deserialize = textutils.unserialize,
  }
  server="o4lIZ0lLc955aNJSHz59UnDxxSqWrmbtXniuITeHqTo="
  local connection = protocal:connect(server, "top")
  print(select(2,connection:receive()))
  connection:send({password="pass",hight=98})