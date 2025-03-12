local LUA_VERSION = "3.0.5";

TEST = false
GlobalPath = ""

local REMOTE_VERSION_CONSTRAINT = function (major, minor, revision)
  if major > 3 then
    return true
  elseif major == 3 then
    if minor > 0 then
      return true
    elseif minor == 0 then
      return revision >= 0
    else
      return false
    end
  else
    return false
  end
end

local CommonFile = assert(loadfile(GlobalPath .. "common.lua"))()
Product = CommonFile.Product
Module = CommonFile.Module
Sensor = CommonFile.Sensor
Dialog = CommonFile.Dialog
Progress = CommonFile.Progress

STR = assert(loadfile(GlobalPath .. "i18n/i18n.lua"))().translate

local function name()
  return STR("ScriptName")
end

-- Data related
local STATE_READ = 1
local STATE_RECEIVE = 2
local STATE_FINISHED = 3
local STATE_PASS = 4

local nextOpTime = nil
local finalTime = nil
local OPERATION_TIMEOUT = 1 -- second(s)
local MAX_TIMEOUT = 10

local supportFields = nil

local createNeeded = false
local createFunction = nil

local file = nil
local SAVE_STATE_REQUEST_NEXT = 0
local SAVE_STATE_REQUEST_CURRENT = 1
local SAVE_STATE_RESPONSE = 2
local SAVE_STATE_FINISH = 3
local LOAD_STATE_READ = 0
local LOAD_STATE_WRITE = 1
local LOAD_STATE_FINISH = 2
local saveLoadState = SAVE_STATE_REQUEST_CURRENT
local FIRST_ADDRESS = 0xA5
local LAST_ADDRESS = 0xD2
local backupAddress = FIRST_ADDRESS
local fileSize = nil
local fileLine = nil
local loadSize = nil
local function isAddressSupportBackup(address)
  return (address >= 0xA5 and address <= 0xB1)
      or (address >= 0xB3 and address <= 0xB8)
      or (address >= 0xC0 and address <= 0xD2)
end

local REMOTE_DEVICE = {address = 0xFE, state = STATE_READ, field = nil, label = STR("RemoteDevice"), dataHandler = function (value, task)
  Product.family = (value >> 8) & 0xFF
  Product.id = (value >> 16) & 0xFF
  print("Remote device family: " .. Product.family .. ", product: " .. Product.id)
  local FrSkyProducts = assert(loadfile(GlobalPath .. "products.lua"))()
  for i, family in pairs(FrSkyProducts) do
    if family.ID == Product.family then
      for j, product in pairs(family.Products) do
        if product.ID == Product.id then
          supportFields = product.SupportFields
          if task.field ~= nil then
            task.field:value(product.Name)
            task.state = STATE_PASS
            return
          end
        end
      end
    end
  end
  if task.field ~= nil then
    task.field:value(STR("UnsupportDevice"))
  end
end}
local REMOTE_VERSION = {address = 0xFF, state = STATE_READ, field = nil, label = STR("RemoteVersion"), dataHandler = function (value, task)
  local major = (value >> 8) & 0xFF
  local minor = (value >> 16) & 0xFF
  local revision = (value >> 24) & 0xFF
  local remoteVersion = string.format("%d.%d.%d", major, minor, revision)
  print("Remote version: " .. remoteVersion)
  if REMOTE_VERSION_CONSTRAINT(major, minor, revision) then
    if task.field ~= nil then
      task.field:value(remoteVersion)
      task.state = STATE_PASS
    end
  else
    if task.field ~= nil then
      task.field:value(STR("UncompitableVersion"))
    end
  end
end}
local tasks = {REMOTE_DEVICE, REMOTE_VERSION}
local currentTask = nil
local function clearAllTasks()
  for i, task in pairs(tasks) do
    task.state = STATE_READ
    if task.field ~= nil then
      task.field:value(STR("Reading"))
    end
  end
  supportFields = nil
  Product.resetProduct()
end

local pages = {{file = assert(loadfile(GlobalPath .. "basic/basic.lua")()), label = STR("BasicConfig")},
               {
                 name = STR("StabilizerGroup1"),
                 subPages = {
                   {file = assert(loadfile(GlobalPath .. "group1/precali1.lua")()), label = STR("Calibration")},
                   {file = assert(loadfile(GlobalPath .. "group1/stab1.lua")()), label = STR("Configuration")},}
                 },
               {
                 name = STR("StabilizerGroup2"),
                 subPages = {
                   {file = assert(loadfile(GlobalPath .. "group2/precali2.lua")()), label = STR("Calibration")},
                   {file = assert(loadfile(GlobalPath .. "group2/stab2.lua")()), label = STR("Configuration")},}
                 },
               {file = assert(loadfile(GlobalPath .. "cali/cali.lua")()), label = STR("SixAxisCali")}}

local currentPage = nil

local function getPage(page)
  return page.file
end

local restoreFileName = ""
local function buildBackupForm(ePanel, focusRefresh)
  if ePanel == nil then
    return
  end
  ePanel:clear()

  local ePanelLine = ePanel:addLine("")
  local slots = form.getFieldSlots(ePanelLine, {270, "- "..STR("Load").." -","- "..STR("Save").." -"})

  form.addFileField(ePanelLine, slots[1], "", "csv+ext", function ()
    return restoreFileName
  end, function (newFile)
    restoreFileName = newFile
  end)

  form.addTextButton(ePanelLine, slots[2], STR("Load"), function()
    print("Load pressed")
    file = nil
    fileSize = nil
    fileLine = nil
    loadSize = 0
    if not restoreFileName or restoreFileName == "" then
      Dialog.openDialog({title = STR("NoFileSelected"), message = STR("SelectFileFirstly"), buttons = {{label = STR("OK"), action = function () Dialog.closeDialog() end}},})
      return
    end

    file = io.open(restoreFileName, "r+")
    if file == nil then
      Dialog.openDialog({title = STR("LoadFailed"), message = STR("FileReadError"), buttons = {{label = STR("OK"), action = function () Dialog.closeDialog() end}},})
      return
    end

    print("Open file: ", restoreFileName)
    local status, size = pcall(function()
      local size = file:seek("end")
      file:seek("set")
      return size
    end)

    if status then
      fileSize = size
    else
      print("file:seek() is not supported")
    end

    if not Progress.isDialogOpen() then
      saveLoadState = LOAD_STATE_READ
      backupAddress = FIRST_ADDRESS
      Progress.openProgressDialog({title = STR("Loading"), message = STR("LoadingConfigurations", {progress = "0"}), close = function ()
        file:close()
        file = nil
        print("Close file: ", restoreFileName)
        Progress.clearDialog()
      end, wakeup = function ()
        if saveLoadState == LOAD_STATE_READ then
          fileLine = file:read("l")
          saveLoadState = LOAD_STATE_WRITE

        elseif saveLoadState == LOAD_STATE_WRITE then
          if fileLine == nil then
            saveLoadState = LOAD_STATE_FINISH
            Progress.message(STR("ConfigFileLoaded", {name = '\n' .. restoreFileName}))
            Progress.value(100)
            return
          end

          local lineData = {}
          for value in fileLine:gmatch("([^,]+)") do
            lineData[#lineData + 1] = tonumber(value)
            if #lineData >= 2 then
              break
            end
          end
          if lineData[1] ~= nil and lineData[2] ~= nil and Sensor.writeParameter(lineData[1], lineData[2]) then
            print("Sensor.writeParameter: " .. string.format("%X", lineData[1]) .. ", value: ", string.format("%X", lineData[2]))
            saveLoadState = LOAD_STATE_READ
            loadSize = loadSize + #fileLine + 1
            local progress
            if fileSize then
              progress = math.ceil(loadSize * 100 / fileSize)
            else
              progress = math.ceil((backupAddress - FIRST_ADDRESS) * 100 / (LAST_ADDRESS - FIRST_ADDRESS + 1))
              backupAddress = backupAddress + 1
            end
            Progress.message(STR("LoadingConfigurations", {progress = "" .. progress}))
            Progress.value(progress)
            fileLine = nil
          end
        end
      end})
    else
      file:close()
      file = nil
    end
  end)

  local button = form.addTextButton(ePanelLine, slots[3], STR("Save"), function()
    file = nil
    if not Progress.isDialogOpen() then
      print("Save pressed")
      local configPrefix = model.name():gsub("%s", "_")
      local configSuffix = ".csv"
      local fileName = configPrefix .. configSuffix
      file = io.open(fileName, "r")
      if file ~= nil then
        for i = 2, 99 do
          fileName = configPrefix .. string.format("%02d", i) .. configSuffix
          file = io.open(fileName, "r")
          if file == nil then
            break
          end
          file:close()
          if i == 99 then
            print("File name not available")
            Dialog.openDialog({title = STR("SaveFailed"), message = STR("CannotSaveToFile"), buttons = {{label = STR("OK"), action = function () Dialog.closeDialog() end}},})
            return
          end
        end
      end

      print("Open file: ", fileName)
      file = io.open(fileName, "w+")
      if file ~= nil then
        backupAddress = FIRST_ADDRESS
        saveLoadState = SAVE_STATE_REQUEST_CURRENT
        Progress.openProgressDialog({title = STR("Saving"), message = STR("SavingConfigurations", {progress = "0"}), close = function ()
          file:close()
          file = nil
          print("Close file: ", fileName)
          -- E.M. will be raised
          -- buildBackupForm(ePanel, true)
          Progress.clearDialog()
        end, wakeup = function ()
          if TEST then
            if file:seek("end") == 0 then
              file:write("A5,0,\n")
              file:seek("set")
            end
            return
          end

          if saveLoadState == SAVE_STATE_RESPONSE then
            local value = Sensor.getParameter()
            -- print("Get value: ", value)
            if (value ~= nil) and (value & 0xFF == backupAddress) then
              local address = value & 0xFF
              value = value >> 8
              local output = "" .. address .. "," .. value .. ",\n"
              file:write(output)
              print("Save value: ", output)
              local progress = math.ceil((backupAddress - FIRST_ADDRESS) * 100 / (LAST_ADDRESS - FIRST_ADDRESS + 1))
              Progress.message(STR("SavingConfigurations", {progress = "" .. progress}))
              Progress.value(progress)
              saveLoadState = SAVE_STATE_REQUEST_NEXT
            elseif os.clock() > nextOpTime then
              saveLoadState = SAVE_STATE_REQUEST_CURRENT
            end

          elseif saveLoadState ~= SAVE_STATE_FINISH then
            if saveLoadState == SAVE_STATE_REQUEST_NEXT then
              backupAddress = backupAddress + 1
              while not isAddressSupportBackup(backupAddress) do
                if backupAddress > LAST_ADDRESS then
                  saveLoadState = SAVE_STATE_FINISH
                  Progress.message(STR("ConfigSaveToFile", {fileName = fileName}))
                  Progress.value(100)
                  return
                end
                backupAddress = backupAddress + 1
              end
              saveLoadState = SAVE_STATE_REQUEST_CURRENT
            end

            if Sensor.requestParameter(backupAddress) then
              print("Request address: ", string.format("%X", backupAddress))
              saveLoadState = SAVE_STATE_RESPONSE
              nextOpTime = os.clock() + OPERATION_TIMEOUT
            end
          end
        end})
      else
        print("Error open file")
        Dialog.openDialog({title = STR("SaveFailed"), message = STR("FSError"), buttons = {{label = STR("OK"), action = function () Dialog.closeDialog() end}}})
      end
    end
  end)

  if focusRefresh then
    button:focus()
  else
    ePanel:open(false)
  end
end

local function buildpage()
  if supportFields == nil then
    return
  end

  local configureForm = form.addExpansionPanel(STR("SaveAndLoad"))
  buildBackupForm(configureForm)

  for index, page in pairs(pages) do
    for i, supportField in pairs(supportFields) do
      if supportField == index then
        if page.name ~= nil then
          local line = form.addLine(page.name)
          local fieldLabels = {}
          for j, subPage in pairs(page.subPages) do
            fieldLabels[#fieldLabels + 1] = "_ "..subPage.label.." _"
          end
          local slots = form.getFieldSlots(line, fieldLabels)
          for j, subPage in pairs(page.subPages) do
            form.addTextButton(line, slots[j], subPage.label, function()
              form.clear()
              local backLine = form.addLine(page.name .. " " .. subPage.label)
              local rect = form.getFieldSlots(backLine, {nil})
              form.addTextButton(backLine, rect[1], STR("Back"), function ()
                if currentPage ~= nil then
                  if getPage(currentPage).close ~= nil then
                    getPage(currentPage).close()
                  end
                  currentPage = nil
                  if createFunction ~= nil then
                    createFunction()
                  end
                  lcd.invalidate()
                  return true
                end
              end)
              currentPage = subPage
              if getPage(currentPage).pageInit ~= nil then
                getPage(currentPage).pageInit()
              end
            end)
          end

        else
          local line = form.addLine(page.label)
          form.addTextButton(line, nil, STR("Open"), function()
            form.clear()
            local backLine = form.addLine(page.label)
            local rect = form.getFieldSlots(backLine, {nil})
            form.addTextButton(backLine, rect[1], STR("Back"), function ()
              if currentPage ~= nil then
                if getPage(currentPage).close ~= nil then
                  getPage(currentPage).close()
                end
                currentPage = nil
                if createFunction ~= nil then
                  createFunction()
                end
                lcd.invalidate()
                return true
              end
            end)
            currentPage = page
            if getPage(currentPage).pageInit ~= nil then
              getPage(currentPage).pageInit()
            end
          end)
        end

        goto continue
      end
    end
    ::continue::
  end
end

local function checkNextTask()
  local allPass = true
  if TEST then
    supportFields = {1, 2, 3, 4}
    Product.family = 2
    Product.id = 79
  end

  for i, task in pairs(tasks) do
    if TEST then
      task.state = STATE_PASS
    end
    if task.state ~= STATE_PASS then
      allPass = false
    end
    if task.state < STATE_FINISHED then
      print("Current task address: ", task.address)
      finalTime = os.clock() + (MAX_TIMEOUT / #tasks)
      return task
    end
  end

  if allPass and supportFields ~= nil then
    buildpage()
  end
  print("All task finished")
  return nil
end

local function taskInit()
  print("Task init")
  clearAllTasks()
  currentTask = checkNextTask()
  nextOpTime = os.clock() + OPERATION_TIMEOUT
end

createFunction = function ()
  if TEST then
    print("Test mode enabled")
  end
  taskInit()

  form.clear()

  local line = form.addLine(STR("ScriptVersion"))
  form.addStaticText(line, nil, LUA_VERSION)

  for i, task in pairs(tasks) do
    line = form.addLine(task.label)
    task.field = form.addStaticText(line, nil, STR("Reading"))
  end

  line = form.addLine(STR("Module"))
  form.addChoiceField(line, nil, {{STR("Internal"), Module.INTERNAL_MODULE}, {STR("External"), Module.EXTERNAL_MODULE}}, function() return Module.CurrentModule end, function(value)
    Sensor.setModule(value)
    createNeeded = true
  end)

  if TEST then
    buildpage()
  end
  return {}
end

local function wakeup()
  if createNeeded then
    if createFunction ~= nil then
      createFunction()
    end
    createNeeded = false
  end
  if currentPage ~= nil then
    if getPage(currentPage).wakeup ~= nil then
      getPage(currentPage).wakeup()
    end
  else
    if currentTask == nil then
      return
    end

    if currentTask.state == STATE_READ or os.clock() >= nextOpTime then
      if Sensor.requestParameter(currentTask.address) then
        print("sensor:requestParameter(), address: ", currentTask.address)
        currentTask.state = STATE_RECEIVE
        nextOpTime = os.clock() + OPERATION_TIMEOUT
      end

    elseif currentTask.state == STATE_RECEIVE then
      local value = Sensor.getParameter()
      if value == nil then
        return
      end

      print("Sensor.getParameter(): " .. value)
      if value & 0xFF ~= currentTask.address then
        return
      end

      currentTask.state = STATE_FINISHED
      currentTask.dataHandler(value, currentTask)
      currentTask = checkNextTask()
    end

    if os.clock() >= finalTime and currentTask ~= nil then
      print("Retries reached")
      currentTask.state = STATE_FINISHED
      if currentTask.field ~= nil then
        currentTask.field:value(STR("UnableToRead"))
      end
      currentTask = checkNextTask()
    end
  end
end

local function paint()
  if currentPage ~= nil and getPage(currentPage).paint ~= nil then
    getPage(currentPage).paint()
  end
end

local function event(pagesData, category, value, x, y)
  if currentPage ~= nil and getPage(currentPage).event ~= nil then
    if getPage(currentPage).event(pagesData, category, value, x, y) then
      return true
    end
  end

  if category == EVT_KEY and value == KEY_EXIT_BREAK then
    if currentPage ~= nil then
      if getPage(currentPage).close ~= nil then
        getPage(currentPage).close()
      end
      currentPage = nil
      if createFunction ~= nil then
        createFunction()
      end
      lcd.invalidate()
      return true
    end
  end
end

local function close()
  currentPage = nil
end

local icon = lcd.loadBitmap("sc.png");

local function init()
  if system.registerDeviceConfig then
    system.registerDeviceConfig({category = DEVICE_CATEGORY_RECEIVERS, name = name, bitmap = icon, appIdStart = Sensor.APPID, appIdEnd = Sensor.APPID, version = LUA_VERSION, pages = { {name = name, create = createFunction, wakeup = wakeup, paint = paint, event = event, close = close} }})
  else
    system.registerSystemTool({name = name, icon = icon, create = createFunction, wakeup = wakeup, paint = paint, event = event, close = close})
  end
end

return { init = init }
