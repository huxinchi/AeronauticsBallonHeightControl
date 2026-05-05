--[[
使用了basalt库做为ui,其链接:https://github.com/Pyroxenium/Basalt2
其许可证链接:https://github.com/Pyroxenium/Basalt2/blob/main/LICENSE
其版权声明:
Copyright (c) 2025 Pyroxenium
]]
function getbasalt()
    local ok, lib = pcall(require, "basalt-full")
    if ok and lib then return lib end
    local ok, lib = pcall(require, "libs/basalt")
    if ok and lib then return lib end
    if not http then
        error("HTTP API is disabled, and basalt was not found locally.")
    end
    print("download basalt-full...")
    local res, err = http.get("https://raw.githubusercontent.com/Pyroxenium/Basalt2/refs/heads/main/release/basalt-full.lua")
    if not res then error("Failed to download basalt: " .. tostring(err)) end
    local src = res.readAll()
    local file = fs.open("basalt-full.lua", "w")
    file.write(src)
    file.close()
    res.close()

    local chunk, loadErr = load(src, "basalt-full", "t", _ENV)
    if not chunk then error("Failed to load basalt: " .. tostring(loadErr)) end
    return chunk()
end
function checkbasalt(basaltt)
    checkfunc=basaltt.getElementManager().hasElement
    return checkfunc("Button") and checkfunc("Input") and checkfunc("Label")
end
basalt=getbasalt()
if not checkbasalt(basalt) then
error("basalt is not full version, please check it")
end
start=false
debug=false
mainframe=basalt.getMainFrame()

out=mainframe:addLabel():setPosition(1, 1):setSize(15,1):setText("no info")
input=mainframe:addInput():setPosition(5, 5):setSize(15,1)
input.placeholder="input height"
configlist=mainframe:addDropDown()
:setPosition(21, 5)
:setSize(9, 1)
:addItem("bottom")
:addItem("top")
:addItem("left")
:addItem("right")
:addItem("front")
:addItem("back")
settings.define("hightctl.outside",{description ="zhe hight ctl output side",default = "right",type = "string"})
configlist.selectedText=settings.get("hightctl.outside","right")
function cconfig(self,index, item)
    settings.load()
    settings.set("hightctl.outside",item.text)
    if settings.save() then
        out:setText("ok")
    elseif settings.get("hightctl.outside","right")== item.text then
        out:setText("error,save to file fail")
    else
        out:setText("setting can not set")
    end 
end
configlist:onSelect(cconfig)
hight=321
kaishiguo=false
function pauseswitch(self)
if not start then
    start=true
    self.text="pause"
else
    start=false
    self.text="resume"
end
end
function run()
while true do
    if start then
        configlist:destroy()
        settings.load()
        outside=settings.get("hightctl.outside","right")
        gaoducha=mainframe:addLabel():setPosition(5, 10):setSize(15,1)
        outputd=mainframe:addLabel():setPosition(5, 11):setSize(15,1)
        pause=mainframe:addButton():setPosition(5, 12):setText("pause"):onClick(pauseswitch)
        Pid = {}

        function Pid.createPid(kp, ki, kd, tick, u)
            local pid = {
                k = 0,
                 u = u,
                e = {},
            }
    
            function pid:step(err)
               self.e[self.k] = err
                if self.k == 0 then
                    self.e[-1] = 0.
                    self.e[-2] = 0.
                end
                local du = kp * (self.e[self.k] - self.e[self.k - 1]) + ki * tick * self.e[self.k] +
                kd * (self.e[self.k] - 2 * self.e[self.k - 1] + self.e[self.k - 2]) / tick
                self.u = self.u + du
                self.k = self.k + 1
                return self.u
            end

            return pid
        end

       --sensor = peripheral.wrap('top')
       local sensors = { peripheral.find("altitude_sensor") }
       
       for _, sensorr in pairs(sensors) do
           if not sensor then
               sensor=sensorr
           else
               out:setText("wann,has more sensor")
           end
       end
--        if (sensor ~= nil) then
          if (sensor == nil)and not debug then
            sensor = peripheral.wrap('top')
            if (sensor==nil)or peripheral.getType(sensor)~="altitude_sensor" then
              printError("sensor not placed")
              gaoducha:setText("error,sensor not placed")
              outputd:setText("error,sensor not placed")
              out:setText("error,sensor not placed")
              start=false
              kaishiguo=false
              return
            end
        end


        control = Pid.createPid(1., .017, 2., 0.1, redstone.getAnalogOutput(outside))
        break
    else sleep(0.5)
    end
end
while true do
    if start==true then
      
      if debug then
        th=100
      else 
        th=sensor.getHeight()
      end
      local output = control:step(hight - th)
      gaoducha:setText("H difference: " .. tostring(hight - th))
      outputd:setText("raw output: " .. tostring(output))
      if output > 15 then
          output = 15
      elseif output < 0 then
          output = 0
      end
      output = math.floor(output)
      redstone.setAnalogOutput(outside, output)
      sleep(0.1)
    else
      sleep(0.5)
    end
end
end
function submitfunc(self)
  hset=1
  extmess=""
  if type(tonumber(input.text))=="nil" then
      out:setText("wrong hight")
      hset=0
  else
      if tonumber(input.text)>=321 then
          extmess=",but Height too high"
      end
      out:setText("ok,hight is:" .. input.text .. extmess)
  end
  if hset==1 then
    hight=tonumber(input.text)
  end
  if not start and hset==1 and not kaishiguo then
    start=true
    kaishiguo=true
    out:setText("start,start hight is:" .. tonumber(hight))
    
  end
end
submit=mainframe:addButton():setPosition(5, 7):setText("submit"):onClick(submitfunc)
local argv = {...}
if (argv[1]=="-h")or(argv[1]=="-help")or(argv[1]=="--help") then
  print("hight ctl\noptions:\n  -h -help --help:get help message\n  -d: start debug mode\n  -H [hight]:set hight and start ctl")
  return
elseif argv[1]=="-H" then
  start=true
  kaishiguo=true
  hight=tonumber(argv[2])
  out:setText("start,start hight is:" .. tonumber(hight))
end
if (argv[1]=="-d")or(argv[3]=="-d") then
  debug=true
  
end
parallel.waitForAll(basalt.run,run)
