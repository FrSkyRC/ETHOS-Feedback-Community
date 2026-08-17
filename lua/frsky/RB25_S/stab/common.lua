local Product = {}
Product.resetProduct = function ()
  Product.family = nil
  Product.id = nil
  Product.supportFields = nil
  Product.caliPrefix = nil
end
Product.exist = function ()
  return Product.family ~= nil and Product.id ~= nil and Product.supportFields ~= nil and Product.caliPrefix ~= nil
end

local Module = {}
Module.INTERNAL_MODULE = 0x00
Module.EXTERNAL_MODULE = 0x01
Module.CurrentModule = Module.INTERNAL_MODULE

local Sensor = {}
Sensor.APPID = 0x0C30
Sensor.sensor = sport.getSensor(Sensor.APPID)
Sensor.setModule = function(module)
  print("Switch to module: ", module)
  Module.CurrentModule = module
  Sensor.sensor:module(module)
end
Sensor.requestParameter = function(page)
  return Sensor.sensor:requestParameter(page)
end
Sensor.writeParameter = function(page, value)
  return Sensor.sensor:writeParameter(page, value)
end
Sensor.getParameter = function()
  return Sensor.sensor:getParameter()
end
Sensor.appId = function(appId)
  return Sensor.sensor:appId(appId)
end

local Dialog = {}
Dialog.dialog = nil
Dialog.clearDialog = function ()
  Dialog.dialog = nil
end
Dialog.isDialogOpen = function ()
  return Dialog.dialog ~= nil
end
Dialog.openDialog = function (dialogParams)
  Dialog.dialog = form.openDialog(dialogParams)
end
Dialog.closeDialog = function ()
  if Dialog.isDialogOpen() then
    Dialog.dialog:close()
    Dialog.clearDialog()
  end
end
Dialog.message = function (newMessage)
  if Dialog.isDialogOpen() then
    Dialog.dialog:message(newMessage)
  end
end

local Progress = {}
Progress.dialog = nil
Progress.clearDialog = function ()
  Progress.dialog = nil
end
Progress.isDialogOpen = function ()
  return Progress.dialog ~= nil
end
Progress.openProgressDialog = function (dialogParams)
  Progress.dialog = form.openProgressDialog(dialogParams)
end
Progress.closeDialog = function ()
  if Progress.isDialogOpen() then
    Progress.dialog:close()
    Progress.clearDialog()
  end
end
Progress.message = function (newMessage)
  if Progress.isDialogOpen() then
    Progress.dialog:message(newMessage)
  end
end
Progress.value = function (newValue)
  if Progress.isDialogOpen() then
    Progress.dialog:value(newValue)
  end
end
Progress.closeAllowed = function (newValue)
  if Progress.isDialogOpen() then
    Progress.dialog:closeAllowed(newValue)
  end
end

return {Product = Product, Module = Module, Sensor = Sensor, Dialog = Dialog, Progress = Progress}
