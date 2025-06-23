local CALI_OPERATION_TIMEOUT = 16 -- seconds
local PUSH_FRAME_TIMEOUT = 2 -- seconds

local CALI_PAGE = 0xB9
local CALI_START_COMMAND = 0x01

local EXC_STATE_READY = 0x00
local EXC_STATE_RUNNING = 0x01
local EXC_STATE_DONE = 0x02

local CALI_STATE_READ = 0x01
local CALI_STATE_RECEIVE = 0x02
local CALI_STATE_WRITE = 0x03
local CALI_STATE_FINISHED = 0x04
local caliState = CALI_STATE_FINISHED

local startCaliParams = nil

local function changeCaliState(newState)
  caliState = newState
end

local function doCalibration()
  if startCaliParams == nil then
    return
  end

  local button = {{label = STR("Close"), action = function ()
    Dialog.closeDialog()
  end}}

  local step = startCaliParams.state
  local finalTick = os.clock() + CALI_OPERATION_TIMEOUT
  local lastPushTick = nil
  changeCaliState(CALI_STATE_WRITE)
  Dialog.openDialog({title = STR("Calibrating"), message = startCaliParams.state == 3 and STR("PreCaliStickRangeHint") or STR("PreCaliWaitHint"), buttons = button, wakeup = function ()
    -- Calibration finished
    if not Dialog.isDialogOpen() or caliState == CALI_STATE_FINISHED then
      return
    end

    -- Calibration timeout
    if finalTick <= os.clock() then
      changeCaliState(CALI_STATE_FINISHED)
      Dialog.message(STR("PreCaliFailed"))
    end

    -- Push reading state frame in the free time
    if caliState == CALI_STATE_READ or (lastPushTick ~= nil and lastPushTick <= os.clock()) then
      print("Push frame at address: " .. CALI_PAGE .. ", step: " .. step)
      if Sensor.requestParameter(CALI_PAGE | (step << 8)) then
        print("Frame pushed!")
        changeCaliState(CALI_STATE_RECEIVE)
        lastPushTick = os.clock() + PUSH_FRAME_TIMEOUT
      end

    -- Push start calibration command
    elseif caliState == CALI_STATE_WRITE then
      if Sensor.writeParameter(CALI_PAGE, step | (CALI_START_COMMAND << 8)) then
        print("Start frame pushed!")
        changeCaliState(CALI_STATE_READ)
        -- Set one frame timeout
        lastPushTick = os.clock() + PUSH_FRAME_TIMEOUT
      end

    -- Handle the received frames
    elseif caliState == CALI_STATE_RECEIVE then
      local value = Sensor.getParameter()
      -- Not received
      if value == nil then
        return
      end

      print("Pop frame with value: " .. value)
      -- Wrong page
      if value & 0xFF ~= CALI_PAGE then
        return
      end

      local excStep = (value >> 8) & 0xFF
      local excStepState = (value >> 16) & 0xFF
      print("With step: " .. excStep .. ", state: " .. excStepState)
      -- Wrong step
      if excStep ~= step then
        return
      end

      -- Received. Clear one frame timeout
      lastPushTick = nil
      if excStepState == EXC_STATE_READY then
        changeCaliState(CALI_STATE_WRITE)
      elseif excStepState == EXC_STATE_RUNNING then
        changeCaliState(CALI_STATE_READ)
      elseif excStepState == EXC_STATE_DONE then
        changeCaliState(CALI_STATE_FINISHED)
        Dialog.message(STR("CalibrationFinished"))
      end
    end
  end})
  startCaliParams = nil
end

local function startCalibration(state)
  local buttons = {{label = STR("Cancel"), action = function ()
    Dialog.closeDialog()
  end},
  {label = STR("OK"), action = function()
    startCaliParams = {state = state}
    Dialog.closeDialog()
  end}}
  local messages = {STR("PreCaliLevelCheckLabel"), STR("PreCaliStickCenterLabel"), STR("PreCaliStickRangeLabel")}
  Dialog.openDialog({title = STR("ConfirmToBegin"), message = messages[state], buttons = buttons})
end

local function pageInit()
  local line = form.addLine("Level calibration")
  form.addTextButton(line, nil, STR("Start"), function ()
    startCalibration(0x01)
  end)

  line = form.addLine(STR("PreCaliStickCenter"))
  form.addTextButton(line, nil, STR("Start"), function ()
    startCalibration(0x02)
  end)

  line = form.addLine(STR("PreCaliStickRange"))
  form.addTextButton(line, nil, STR("Start"), function ()
    startCalibration(0x03)
  end)
end

local function wakeup()
  if startCaliParams ~= nil then
    doCalibration()
  end
end

return {pageInit = pageInit, wakeup = wakeup}
