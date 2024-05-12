----------------------------------------------------------------------------------
-- Ventus W830 Weather Station
-- Version 1.1 (May 2024) - Added WindGust childdevice, rounded numbers
--   and fixed nil bug when value was not send by weatherstation.
-- Version 1.0 (April 2022)
-- Copyright (c)2022-2024 Joep Verhaeg <info@joepverhaeg.nl>

-- Full documentation you can find at:
-- https://docs.joepverhaeg.nl/ventus-w830/
----------------------------------------------------------------------------------
-- DESCRIPTION:
-- This Quick App integrates with the Ventus W830 local API. It shows the
-- weather station readings and uses the correct FIBARO device types.

-- QUICK SETUP:
-- 1. Configure a customized upload server in the WS View app under Device List,
-- 2. Set the IPv4 to a Node-RED or PHP server that accepts the POST JSON payload,
-- 3. Configure the Node-RED or PHP server to forward the payload to this
--    Ventus W830 Quick App (an example is included in the documentation).
----------------------------------------------------------------------------------
__TAG = "QAVENTUS" .. plugin.mainDeviceId
_VERSION = "1.1"

local function getChildVariable(child, varName)
    for _,v in ipairs(child.properties.quickAppVariables or {}) do
        if (v.name == varName) then
            return v.value
        end
    end
    return ""
end

local function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

class 'Sensor'(QuickAppChild)
function Sensor:__init(device)
    -- You should not insert code before QuickAppChild.__init.
    QuickAppChild.__init(self, device)
end

function Sensor:updateValue(propertyName, weatherdata)
    if propertyName == "tempinf" then
        -- Convert temperature from Fahrenheit to Celcius
        local tempinc = (tonumber(weatherdata['tempinf']) - 32) * 5 / 9
        self:updateProperty("value", round(tempinc, 2))
    elseif propertyName == "tempf" then
        local tempc = (tonumber(weatherdata['tempf']) - 32) * 5 / 9
        self:updateProperty("value", round(tempc, 2))
    elseif propertyName == "uv" then
        local uvi = tonumber(weatherdata['uv'])
        if uvi == 0 then
            uvalert = "None"
        elseif uvi <= 2 then
            uvalert = "Very Low"
        elseif uvi <= 4 then
            uvalert = "Low"
        elseif uvi <= 6 then
            uvalert = "Moderate"
        elseif uvi <= 8 then
            uvalert = "High"
        elseif uvi >= 9 then
            uvalert = "Very High"
        end
        self:updateProperty("value", uvi)
        self:updateProperty("log", uvalert)
    elseif propertyName == "baromabsin" then
        -- Convert barometric pressure from inHg to hPa
        local baromabsin = math.floor((tonumber(weatherdata['baromabsin'])/0.029529983071445)*100)/100
        self:updateProperty("value", round(baromabsin, 2))
    elseif propertyName == "windspeedmph" then
        local windspeedkmh = tonumber(weatherdata['windspeedmph'])*1.609344
        self:updateProperty("value", round(windspeedkmh, 2))
    elseif propertyName == "windgustmph" then
        local windgustmph = tonumber(weatherdata['windgustmph'])*1.609344
        self:updateProperty("value", round(windgustmph, 2))
        local maxdailygust  = tonumber(weatherdata['maxdailygust'])*1.609344
        self:updateProperty("log", "Max: " .. round(maxdailygust, 2) .. " km/u")
    elseif propertyName == "dailyrainin" then
        local dailyrainin = tonumber(weatherdata['dailyrainin'])*25.4
        local monthlyrainin  = math.floor((tonumber(weatherdata['monthlyrainin'])*25.4)*10)/10
        self:updateProperty("value", dailyrainin)
        self:updateProperty("log", "Month: " .. monthlyrainin .. " mm")
    else
        -- Parse the other properties
        self:updateProperty("value", tonumber(weatherdata[propertyName]))
    end
end

function QuickApp:data(weatherdata)
    self:updateView("labelStationType", "text", weatherdata['stationtype'])
    self:updateView("labelModel", "text", weatherdata['model'])
    self:updateView("labelDateUtc", "text", weatherdata['dateutc'] .. " UTC")
    self:updateProperty("log", os.date('%d-%m %H:%M:%S'))
    for id, child in pairs(self.childDevices) do
        local propertyName = child:getVariable("propertyName")
        if weatherdata[propertyName] then
            child:updateValue(propertyName, weatherdata)
        end
    end
end

function QuickApp:onInit()
    self:debug("Initialising Ventus W830 integration v" .. _VERSION)

    self.childsInitialized = true
    if not api.get("/devices/" .. self.id).enabled then
        self:warning("The Ventus W830 weather station device is disabled!")
        return
    end

    local cdevs = api.get("/devices?parentId="..self.id) or {}
    if #cdevs == 0 then
        -- Child devices are not created yet, create them...
        initChildData = {
            {name="Indoor Temperature", className="Sensor", propertyName="tempinf", type="com.fibaro.temperatureSensor"},
            {name="Indoor Humidity", className="Sensor", propertyName="humidityin", type="com.fibaro.humiditySensor"},
            {name="Baromatric Pressure", className="Sensor", propertyName="baromabsin", type="com.fibaro.multilevelSensor", unit="hPa"},
            {name="Outdoor Temperature", className="Sensor", propertyName="tempf", type="com.fibaro.temperatureSensor"},
            {name="Outdoor Humidity", className="Sensor", propertyName="humidity", type="com.fibaro.humiditySensor"},
            {name="Wind Speed", className="Sensor", propertyName="windspeedmph", type="com.fibaro.windSensor", unit="km/h"},
            {name="Wind Gust", className="Sensor", propertyName="windgustmph", type="com.fibaro.windSensor", unit="km/h"},
            {name="Rain Fall", className="Sensor", propertyName="dailyrainin", type="com.fibaro.rainSensor", unit="mm"},
            {name="Light", className="Sensor", propertyName="solarradiation", type="com.fibaro.multilevelSensor", unit="w/m2"},
            {name="UV index", className="Sensor", propertyName="uv", type="com.fibaro.multilevelSensor", unit="UVI"}
        }
        for _,c in ipairs(initChildData) do
            local child = self:createChildDevice(
                {
                    name = c.name,
                    type=c.type,
                    initialProperties = {},
                    initialInterfaces = {},
                },
                _G[c.className] -- Fetch class constructor from class name
            )
            child:setVariable("className", c.className)  -- Save class name so we know when we load it next time.
            child:setVariable("propertyName", c.propertyName)
            if (c.unit ~= nil) then
                child:updateProperty("unit", c.unit)
            end
            child.parent = self
            self:debug("Child device " .. child.name .. " created with id: ", child.id)
        end
    else
        -- Ok, we already have children, instantiate them with the correct class
        -- This is more or less what self:initChildDevices does but this can handle
        -- mapping different classes to the same type...
        for _,child in ipairs(cdevs) do
            local className = getChildVariable(child,"className") -- Fetch child class name
            local childObject = _G[className](child) -- Create child object from the constructor name
            self.childDevices[child.id]=childObject
            childObject.parent = self -- Setup parent link to device controller
        end
    end
end