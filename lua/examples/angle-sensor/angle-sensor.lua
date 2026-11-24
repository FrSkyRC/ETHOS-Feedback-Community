-- System / Angle sensor: SkyRC SAM-020 angle sensors (up to 3)
-- Discovers the sensors, connects each one found and shows a gauge per sensor.

local MAX_SENSORS = 3
local ZONE_HALF_WIDTH = 45 -- degrees, green zone around the horizontal
local SCAN_DURATION = 10 -- seconds, the duration of the discover of the module
local CONNECT_TIMEOUT = 30 -- seconds, the module connects the devices one after the other
local READ_PERIOD = 0.05 -- seconds
local ANGLE_UUID = "FFE1"

local function openMessage(title, message)
    form.openDialog({
        title = title,
        message = message,
        buttons = {{label = "OK", action = function() return true end}}
    })
end

-- SAM-020: advertises as "SAM20-xxxx" and its Bluetooth address starts with DC:23:4F:C7
local function isSamSensor(device)
    return device.name:sub(1, 6) == "SAM20-" or device.address:upper():sub(1, 11) == "DC:23:4F:C7"
end

-- Two concentric circles with a green zone around the horizontal, the value at the center, and a needle at the
-- measured angle (3 o'clock = 0 degree, positive is upwards). Until the sensor is connected the value is "---",
-- greyed, and there is no needle.
local function paintGauge(x, y, w, h, sensor)
    local padding = w >= 400 and 8 or 4
    local cx = x + w // 2
    local cy = y + h // 2
    local radius = math.min(w, h) // 2 - padding -- the whole drawing, needle included
    local outer = radius * 10 // 11
    local inner = outer * 6 // 10

    local disabled = lcd.themeColor(THEME_DISABLE_COLOR)

    lcd.color(disabled)
    lcd.drawCircle(cx, cy, outer)
    lcd.drawCircle(cx, cy, inner)
    lcd.color(lcd.themeColor(THEME_SAFE_COLOR))
    lcd.drawAnnulusSector(cx, cy, inner + 1, outer - 1, 90 - ZONE_HALF_WIDTH, 90 + ZONE_HALF_WIDTH)

    lcd.font(FONT_M)
    local _, textHeight = lcd.getTextSize("0")

    if not sensor.connected then
        lcd.color(disabled)
        lcd.drawText(cx, cy - textHeight // 2, "---", TEXT_CENTERED)
        return
    end

    local angle = math.rad(90 - sensor.value / 10)
    local s = math.sin(angle)
    local c = math.cos(angle)
    lcd.color(lcd.themeColor(THEME_PRIMARY_COLOR))
    lcd.drawLine(cx + s * inner, cy - c * inner, cx + s * radius, cy - c * radius)
    lcd.drawNumber(cx, cy - textHeight // 2, sensor.value / 10, UNIT_DEGREE, 1, TEXT_CENTERED)
end

local function closeScanDialog(data)
    if data.scanDialog then
        local dialog = data.scanDialog
        data.scanDialog = nil
        dialog:close()
    end
end

local function startSearch(data)
    data.started = true
    data.phase = "scanning"
    data.found = {}
    data.scanDone = false
    data.scanStart = os.clock()

    bluetooth.startDiscover({
        found = function(device)
            if isSamSensor(device) and #data.found < MAX_SENSORS then
                data.found[#data.found + 1] = device
                if #data.found >= MAX_SENSORS then
                    data.scanDone = true -- enough sensors, the connection requests interrupt the discover
                end
            end
        end,
        done = function()
            data.scanDone = true
        end
    })
end

-- Ends everything and releases the Bluetooth module
local function stopAll(data)
    closeScanDialog(data)
    if data.started then
        bluetooth.stop()
    end
    data.started = false
    data.phase = "idle"
end

local function fail(data, message)
    stopAll(data)
    openMessage("Warning", message)
end

-- brings an angle in tenths of degree back to -180.0 .. 180.0
local function wrapAngle(angle)
    return (angle + 1800) % 3600 - 1800
end

local function connectSensor(data, device)
    -- raw: the angle given by the sensor, offset: set by a touch to have 0 at the current position, value: the angle
    -- shown, both in tenths of degree
    local sensor = {connected = false, raw = 0, offset = 0, value = 0, lastRead = 0, since = os.clock(), dead = false}
    sensor.connection = bluetooth.connect(device, {
        connected = function()
            sensor.connected = true
        end,
        disconnected = function()
            sensor.connected = false
        end,
        read = function(connection, uuid, value)
            if #value >= 2 then
                local raw = string.unpack(">I2", value)
                sensor.raw = raw > 1800 and raw - 3600 or raw
                sensor.value = wrapAngle(sensor.raw + sensor.offset)
            end
        end
    })
    if sensor.connection then
        data.sensors[#data.sensors + 1] = sensor
    end
end

local function connectFound(data)
    data.sensors = {}
    for _, device in ipairs(data.found) do
        connectSensor(data, device)
    end
    data.phase = "connecting"
end

local function updateScanDialog(data)
    if data.phase ~= "scanning" or data.scanCancelled then
        closeScanDialog(data)
        return
    end

    if not data.scanDialog then
        data.scanDialog = form.openWaitDialog({
            title = "Angle sensor",
            message = "",
            progress = true,
            closeLabel = "Cancel",
            close = function()
                -- cancelled by the user: nothing found, all is cancelled. Otherwise we go on with the sensors found
                data.scanDialog = nil
                if #data.found == 0 then
                    stopAll(data)
                else
                    data.scanCancelled = true
                    data.scanDone = true
                end
            end
        })
    end

    data.scanDialog:message(string.format("Searching for SAM-020 sensors: %d found", #data.found))
    data.scanDialog:value(math.min(100, (os.clock() - data.scanStart) * 100 / SCAN_DURATION))
end

local function create()
    local data = {
        started = false,
        phase = "idle",
        found = {},
        sensors = {},
        scanDone = false,
        scanCancelled = false,
        scanDialog = nil,
        scanStart = 0,
        signature = ""
    }

    local current = bluetooth.getCurrentModeName()
    if current then
        form.openDialog({
            title = "Confirm",
            message = string.format("Bluetooth is used by %s. Stop it?", current),
            buttons = {
                {label = "OK", action = function() startSearch(data) return true end},
                {label = "Cancel", action = function() return true end}
            }
        })
    else
        startSearch(data)
    end

    return data
end

local function wakeup(data)
    if not data.started then
        return
    end

    if data.phase == "scanning" then
        updateScanDialog(data)
        if data.scanDone then
            closeScanDialog(data)
            if #data.found == 0 then
                fail(data, "No Bluetooth device found")
                return
            end
            connectFound(data)
        end
    end

    if data.phase == "connecting" then
        local connecting = false
        for _, sensor in ipairs(data.sensors) do
            if not sensor.dead and not sensor.connected and sensor.connection:isConnecting() then
                if os.clock() - sensor.since > CONNECT_TIMEOUT then
                    sensor.connection:disconnect() -- the module stops retrying
                    sensor.dead = true
                else
                    connecting = true
                end
            end
        end
        if not connecting then
            data.phase = "idle"
            local connected = false
            for _, sensor in ipairs(data.sensors) do
                connected = connected or sensor.connected
            end
            if not connected then
                fail(data, "Connection refused")
                return
            end
        end
    end

    -- the angle is read again as soon as the previous read is answered
    local now = os.clock()
    local parts = {data.phase}
    for _, sensor in ipairs(data.sensors) do
        if sensor.connected and now - sensor.lastRead >= READ_PERIOD then
            if sensor.connection:read(ANGLE_UUID) then
                sensor.lastRead = now
            end
        end
        parts[#parts + 1] = sensor.dead and "x" or (sensor.connected and sensor.value or "-")
    end

    local signature = table.concat(parts, ",")
    if signature ~= data.signature then
        data.signature = signature
        lcd.invalidate()
    end
end

-- A touch on a gauge calibrates its sensor: the current angle becomes the 0
local function event(data, category, value, x, y)
    if category == EVT_TOUCH and value == TOUCH_END and data.slotWidth and data.slotWidth > 0 then
        local sensor = data.gauges[x // data.slotWidth + 1]
        if sensor and sensor.connected then
            sensor.offset = -sensor.raw
            sensor.value = 0
            lcd.invalidate()
            system.killEvent(value)
            return true
        end
    end
    return false
end

local function paint(data)
    local w, h = lcd.getWindowSize()

    local gauges = {}
    for _, sensor in ipairs(data.sensors) do
        if not sensor.dead then
            gauges[#gauges + 1] = sensor
        end
    end

    if #gauges == 0 then
        if data.phase == "idle" then
            lcd.color(lcd.themeColor(THEME_PRIMARY_COLOR))
            lcd.font(FONT_L)
            local _, textHeight = lcd.getTextSize("Not connected")
            lcd.drawText(w // 2, (h - textHeight) // 2, "Not connected", TEXT_CENTERED)
        end
        return
    end

    -- the gauges side by side, sharing the width
    local slotWidth = w // #gauges
    data.gauges = gauges
    data.slotWidth = slotWidth
    for i, sensor in ipairs(gauges) do
        paintGauge((i - 1) * slotWidth, 0, slotWidth, h, sensor)
    end
end

local function close(data)
    stopAll(data)
end

return {
  create = create,
  wakeup = wakeup,
  event = event,
  paint = paint,
  close = close,
}
