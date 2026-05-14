--[[
使用了basalt库做为ui,其链接:https://github.com/Pyroxenium/Basalt2
其许可证链接:https://github.com/Pyroxenium/Basalt2/blob/main/LICENSE
其版权声明:
Copyright (c) 2025 Pyroxenium
]]
--获取basalt
function getbasalt()
    local ok, lib = pcall(require, "basalt-full")--尝试导入完整版
    if ok and lib then return lib end--如果成功就退出
    local ok, lib = pcall(require, "libs/basalt")--尝试导入dev版
    if ok and lib then return lib end--如果成功就退出
    if not http then--如果没开http
        error("HTTP API is disabled, and basalt was not found locally.")
    end
    print("download basalt-full...")--准备自动下载
    local res, err = http.get("https://raw.githubusercontent.com/Pyroxenium/Basalt2/refs/heads/main/release/basalt-full.lua")--下载
    if not res then error("Failed to download basalt: " .. tostring(err)) end--错误处理
    local src = res.readAll()--读下载的内容
    local file = fs.open("basalt-full.lua", "w")--写到文件里
    file.write(src)
    file.close()
    res.close()

    local chunk, loadErr = load(src, "basalt-full", "t", _ENV)--直接加载
    if not chunk then error("Failed to load basalt: " .. tostring(loadErr)) end--错误处理
    return chunk()
end
--检查使用到的元素是否可用
function checkbasalt(basaltt)
    checkfunc=basaltt.getElementManager().hasElement
    return checkfunc("Button") and checkfunc("Input") and checkfunc("Label") and checkfunc("DropDown")
end
basalt=getbasalt()--导入basalt
if not checkbasalt(basalt) then
error("basalt is not full version, please check it")--如果检查失败就报错
end
start=false
debug=false
mainframe=basalt.getMainFrame()--获取主frame

out=mainframe:addLabel():setPosition(1, 1):setSize(15,1):setText("no info")--输出
input=mainframe:addInput():setPosition(5, 5):setSize(15,1)--输入
input.placeholder="input height"
configlist=mainframe:addDropDown()--方向配置
:setPosition(21, 5)
:setSize(9, 1)
:addItem("bottom")
:addItem("top")
:addItem("left")
:addItem("right")
:addItem("front")
:addItem("back")
settings.define("hightctl.outside",{description ="zhe hight ctl output side",default = "right",type = "string"})--定义设置
settings.load()--加载配置
configlist.selectedText=settings.get("hightctl.outside","right")--设置默认当前配置
function cconfig(self,index, item)--设置配置
    settings.load()--加载
    settings.set("hightctl.outside",item.text)--设置
    if settings.save() then--保存
        out:setText("ok")--成功
    elseif settings.get("hightctl.outside","right")== item.text then
        out:setText("error,save to file fail")--文件写入失败
    else
        out:setText("setting can not set")--配置写入失败
    end 
end
configlist:onSelect(cconfig)--注册回调
hight=321
kaishiguo=false
function pauseswitch(self)--切换状态
if not start then
    start=true
    self.text="pause"
else
    start=false
    self.text="resume"
end
end
function onstoplog(self)
dataf.writeLine(']')
stoplog=true
dataf.close()
self:destroy()
out:setText("ok,stop log")
end
function run()--控制主函数
while true do
    if start then
        configlist:destroy()--炸了配置列表
        settings.load()--加载配置
        outside=settings.get("hightctl.outside","right")--获取方向
        gaoducha=mainframe:addLabel():setPosition(5, 10):setSize(15,1)--高度差显示
        outputd=mainframe:addLabel():setPosition(5, 11):setSize(15,1)--输出显示
        pause=mainframe:addButton():setPosition(5, 12):setText("pause"):onClick(pauseswitch)--暂停按键
        
        Pid = {}--写pid
        if logtofile then
            dataf = fs.open('data.json', 'w')
            dataf.writeLine('[')
            mainframe:addButton():setPosition(5, 15):setText("stoplog"):onClick(onstoplog)
        end
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

       
       local sensors = { peripheral.find("altitude_sensor") }--找高度计
       
       for _, sensorr in pairs(sensors) do
           if not sensor then
               sensor=sensorr--把当前设置为这个
           else
               out:setText("wann,has more sensor")--如果有多个就警告
           end
       end
          if (sensor == nil)and not debug then--如果没有找到并且不是调试模式
            sensor = peripheral.wrap('top')--尝试使用上方
            if (sensor==nil)or peripheral.getType(sensor)~="altitude_sensor" then--如果还是没有或者类型不是高度传感器
              printError("sensor not placed")
              gaoducha:setText("error,sensor not placed")
              outputd:setText("error,sensor not placed")
              out:setText("error,sensor not placed")--报错
              start=false--停止
              kaishiguo=false--设置未开始
              return
            end
        end


        control = Pid.createPid(1., .017, 2., 0.1, redstone.getAnalogOutput(outside))--创建pid
        break
    else sleep(1)--如果没有开始，等1秒
    end
end
while true do
    if start==true then--如果开始了
      if debug then
        th=100--如果调试状态，就设置当前高度为100
      else 
        th=sensor.getHeight()--设置当前高度
      end
      if logtofile and not stoplog then
          dataf.writeLine(tostring(th)..",")
      end
      local output = control:step(hight - th)--步进pid
      gaoducha:setText("H difference: " .. tostring(hight - th))--设置高度差
      outputd:setText("raw output: " .. tostring(output))--设置输出
      if output > 15 then
          output = 15--强制拉到15内
      elseif output < 0 then
          output = 0
      end
      output = math.floor(output)--取整
      redstone.setAnalogOutput(outside, output)--输出
      sleep(0.1)--控制延迟
    else
      sleep(1)--等1秒(上面确认过了，这里只是保险)
    end
end
end
function submitfunc(self)
  hset=1
  extmess=""
  if type(tonumber(input.text))=="nil" then--如果无法转换为数字
      out:setText("wrong hight")--报错
      hset=0--不设置
  else
      if tonumber(input.text)>=321 then
          extmess=",but Height too high"--发出警告
      end
      out:setText("ok,hight is:" .. input.text .. extmess)--设置成功提示
  end
  if hset==1 then
    hight=tonumber(input.text)--设置高度
  end
  if not start and hset==1 and not kaishiguo then--第1次启动
    start=true--开始
    kaishiguo=true--设置为开始过
    out:setText("start,start hight is:" .. tonumber(hight))--提示
    
  end
end
submit=mainframe:addButton():setPosition(5, 7):setText("submit"):onClick(submitfunc)--提交修改按键
local argv = {...}--定义参数
if (argv[1]=="-h")or(argv[1]=="-help")or(argv[1]=="--help") then
  print("hight ctl\noptions:\n  -h -help --help:get help message\n  -d: start debug mode\n  -H [hight]:set hight and start ctl\n    -l:start log")--制作help
  return
elseif argv[1]=="-H" then
  start=true--开始
  kaishiguo=true--设置为开始过
  hight=tonumber(argv[2])--设置高度
  out:setText("start,start hight is:" .. tonumber(hight))--设置提示
end
if (argv[1]=="-d")or(argv[3]=="-d")or(argv[4]=="-d") then
  debug=true--开启调试模式
end
if (argv[1]=="-l")or(argv[2]=="-l")or(argv[3]=="-l")or(argv[4]=="-l")then
  logtofile=true
end
parallel.waitForAll(basalt.run,run)--启动
