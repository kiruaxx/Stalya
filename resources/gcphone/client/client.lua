--====================================================================================
-- #Author: Jonathan D @ Gannon
--====================================================================================

-- Configuration
local KeyToucheCloseEvent = {
    { code = 172, event = 'ArrowUp' },
    { code = 173, event = 'ArrowDown' },
    { code = 174, event = 'ArrowLeft' },
    { code = 175, event = 'ArrowRight' },
    { code = 176, event = 'Enter' },
    { code = 177, event = 'Backspace' },
}

local menuIsOpen = false
local contacts = {}
local messages = {}
local myPhoneNumber = ''
local isDead = false
local USE_RTC = false
local useMouse = false
local ignoreFocus = false
local takePhoto = false
local hasFocus = false
local TokoVoipID = nil

local PhoneInCall = {}
local currentPlaySound = false
local soundDistanceMax = 8.0


--====================================================================================
--  Check si le joueurs poséde un téléphone
--  Callback true or false
--====================================================================================
function hasPhone (cb)
    cb(true)
end
--====================================================================================
--  Que faire si le joueurs veut ouvrir sont téléphone n'est qu'il en a pas ?
--====================================================================================
function ShowNoPhoneWarning ()
end

--[[
  Ouverture du téphone lié a un item
  Un solution ESC basé sur la solution donnée par HalCroves
  https://forum.fivem.net/t/tutorial-for-gcphone-with-call-and-job-message-other/177904
]]--

ESX = nil
--[[
function hasPhone (cb)
  if (ESX == nil) then return cb(0) end
  ESX.TriggerServerCallback('gcphone:getItemAmount', function(qtty)
    cb(qtty > 0)
  end, 'phone')
end
function ShowNoPhoneWarning () 
  if (ESX == nil) then return end
  ESX.ShowNotification("Vous n'avez pas de ~r~téléphone~s~")
end --]]

--====================================================================================
--  
--====================================================================================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if not menuIsOpen and isDead then
            DisableControlAction(0, 288, true)
        end
        if takePhoto ~= true then
            if IsControlJustPressed(1, Config.KeyOpenClose) then
                hasPhone(function(hasPhone)
                    if hasPhone == true then
                        TooglePhone()
                    else
                        ShowNoPhoneWarning()
                    end
                end)
            end
            if menuIsOpen == true then
                for _, value in ipairs(KeyToucheCloseEvent) do
                    if IsControlJustPressed(1, value.code) then
                        SendNUIMessage({ keyUp = value.event })
                    end
                end
                if useMouse == true and hasFocus == ignoreFocus then
                    local nuiFocus = not hasFocus
                    SetNuiFocus(nuiFocus, nuiFocus)
                    hasFocus = nuiFocus
                elseif useMouse == false and hasFocus == true then
                    SetNuiFocus(false, false)
                    hasFocus = false
                end
            else
                if hasFocus == true then
                    SetNuiFocus(false, false)
                    hasFocus = false
                end
            end
        end
    end
end)



--====================================================================================
--  Active ou Deactive une application (appName => config.json)
--====================================================================================
RegisterNetEvent('gcPhone:setEnableApp')
AddEventHandler('gcPhone:setEnableApp', function(appName, enable)
    SendNUIMessage({ event = 'setEnableApp', appName = appName, enable = enable })
end)

--====================================================================================
--  Gestion des appels fixe
--====================================================================================
function startFixeCall (fixeNumber)
    local number = ''
    DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "", "", "", "", "", 10)
    while (UpdateOnscreenKeyboard() == 0) do
        DisableAllControlActions(0);
        Wait(0);
    end
    if (GetOnscreenKeyboardResult()) then
        number = GetOnscreenKeyboardResult()
    end
    if number ~= '' then
        TriggerEvent('gcphone:autoCall', number, {
            useNumber = fixeNumber
        })
        PhonePlayCall(true)
    end
end

function TakeAppel (infoCall)
    TriggerEvent('gcphone:autoAcceptCall', infoCall)
end

RegisterNetEvent("gcPhone:notifyFixePhoneChange")
AddEventHandler("gcPhone:notifyFixePhoneChange", function(_PhoneInCall)
    PhoneInCall = _PhoneInCall
end)

function PlaySoundJS (sound, volume)
    SendNUIMessage({ event = 'playSound', sound = sound, volume = volume })
end

function SetSoundVolumeJS (sound, volume)
    SendNUIMessage({ event = 'setSoundVolume', sound = sound, volume = volume })
end

function StopSoundJS (sound)
    SendNUIMessage({ event = 'stopSound', sound = sound })
end

RegisterNetEvent("gcPhone:forceOpenPhone")
AddEventHandler("gcPhone:forceOpenPhone", function(_myPhoneNumber)
    if menuIsOpen == false then
        TooglePhone()
    end
end)

--====================================================================================
--  Events
--====================================================================================
RegisterNetEvent("gcPhone:myPhoneNumber")
AddEventHandler("gcPhone:myPhoneNumber", function(_myPhoneNumber)
    myPhoneNumber = _myPhoneNumber
    SendNUIMessage({ event = 'updateMyPhoneNumber', myPhoneNumber = myPhoneNumber })
end)

RegisterNetEvent("gcPhone:contactList")
AddEventHandler("gcPhone:contactList", function(_contacts)
    SendNUIMessage({ event = 'updateContacts', contacts = _contacts })
    contacts = _contacts
end)

RegisterNetEvent("gcPhone:allMessage")
AddEventHandler("gcPhone:allMessage", function(allmessages)
    SendNUIMessage({ event = 'updateMessages', messages = allmessages })
    messages = allmessages
end)

RegisterNetEvent("gcPhone:getBourse")
AddEventHandler("gcPhone:getBourse", function(bourse)
    SendNUIMessage({ event = 'updateBourse', bourse = bourse })
end)

RegisterNetEvent("gcPhone:receiveMessage")
AddEventHandler("gcPhone:receiveMessage", function(message)
    -- SendNUIMessage({event = 'updateMessages', messages = messages})
    SendNUIMessage({ event = 'newMessage', message = message })
    table.insert(messages, message)
    if message.owner == 0 then
        local text = string.format('Nouveau message du %s', message.transmitter)
        for _, contact in pairs(contacts) do
            if contact.number == message.transmitter then
                text = string.format('Nouveau message de %s', contact.display)
                break
            end
        end
        SetNotificationTextEntry("STRING")
        AddTextComponentString(text)
        DrawNotification(false, false)
        PlaySound(-1, "Menu_Accept", "Phone_SoundSet_Default", 0, 0, 1)
        Citizen.Wait(300)
        PlaySound(-1, "Menu_Accept", "Phone_SoundSet_Default", 0, 0, 1)
        Citizen.Wait(300)
        PlaySound(-1, "Menu_Accept", "Phone_SoundSet_Default", 0, 0, 1)
    end
end)

--====================================================================================
--  Function client | Contacts
--====================================================================================
function addContact(display, num)
    TriggerServerEvent('gcPhone:addContact', display, num)
end

function deleteContact(num)
    TriggerServerEvent('gcPhone:deleteContact', num)
end
--====================================================================================
--  Function client | Messages
--====================================================================================
function sendMessage(num, message)
    TriggerServerEvent('gcPhone:sendMessage', num, message)
end

function deleteMessage(msgId)
    TriggerServerEvent('gcPhone:deleteMessage', msgId)
    for k, v in ipairs(messages) do
        if v.id == msgId then
            table.remove(messages, k)
            SendNUIMessage({ event = 'updateMessages', messages = messages })
            return
        end
    end
end

function deleteMessageContact(num)
    TriggerServerEvent('gcPhone:deleteMessageNumber', num)
end

function deleteAllMessage()
    TriggerServerEvent('gcPhone:deleteAllMessage')
end

function setReadMessageNumber(num)
    TriggerServerEvent('gcPhone:setReadMessageNumber', num)
    for k, v in ipairs(messages) do
        if v.transmitter == num then
            v.isRead = 1
        end
    end
end

function requestAllMessages()
    TriggerServerEvent('gcPhone:requestAllMessages')
end

function requestAllContact()
    TriggerServerEvent('gcPhone:requestAllContact')
end



--====================================================================================
--  Function client | Appels
--====================================================================================
local aminCall = false
local inCall = false

RegisterNetEvent("gcPhone:waitingCall")
AddEventHandler("gcPhone:waitingCall", function(infoCall, initiator)
    SendNUIMessage({ event = 'waitingCall', infoCall = infoCall, initiator = initiator })
    if initiator == true then
        PhonePlayCall()
        if menuIsOpen == false then
            TooglePhone()
        end
    end
end)

RegisterNetEvent("gcPhone:acceptCall")
AddEventHandler("gcPhone:acceptCall", function(infoCall, initiator)
    if inCall == false and USE_RTC == false then
        inCall = true
        if Config.UseMumbleVoIP then
            exports["mumble-voip"]:SetCallChannel(infoCall.id + 1)
        elseif Config.UseTokoVoIP then
            exports.tokovoip_script:addPlayerToRadio(infoCall.id + 120)
            TokoVoipID = infoCall.id + 120
        else
            NetworkSetVoiceChannel(infoCall.id + 1)
            NetworkSetTalkerProximity(0.0)
        end
    end
    if menuIsOpen == false then
        TooglePhone()
    end
    PhonePlayCall()
    SendNUIMessage({ event = 'acceptCall', infoCall = infoCall, initiator = initiator })
end)

RegisterNetEvent("gcPhone:rejectCall")
AddEventHandler("gcPhone:rejectCall", function(infoCall)
    if inCall == true then
        inCall = false
        if Config.UseMumbleVoIP then
            exports["mumble-voip"]:SetCallChannel(0)
        elseif Config.UseTokoVoIP then
            exports.tokovoip_script:removePlayerFromRadio(TokoVoipID)
            TokoVoipID = nil
        else
            Citizen.InvokeNative(0xE036A705F989E049)
            NetworkSetTalkerProximity(2.5)
        end
    end
    PhonePlayText()
    SendNUIMessage({ event = 'rejectCall', infoCall = infoCall })
end)

RegisterNetEvent("gcPhone:historiqueCall")
AddEventHandler("gcPhone:historiqueCall", function(historique)
    SendNUIMessage({ event = 'historiqueCall', historique = historique })
end)

function startCall (phone_number, rtcOffer, extraData)
    if rtcOffer == nil then
        rtcOffer = ''
    end
    TriggerServerEvent('gcPhone:startCall', phone_number, rtcOffer, extraData)
end

function acceptCall (infoCall, rtcAnswer)
    TriggerServerEvent('gcPhone:acceptCall', infoCall, rtcAnswer)
end

function rejectCall(infoCall)
    TriggerServerEvent('gcPhone:rejectCall', infoCall)
end

function ignoreCall(infoCall)
    TriggerServerEvent('gcPhone:ignoreCall', infoCall)
end

function requestHistoriqueCall()
    TriggerServerEvent('gcPhone:getHistoriqueCall')
end

function appelsDeleteHistorique (num)
    TriggerServerEvent('gcPhone:appelsDeleteHistorique', num)
end

function appelsDeleteAllHistorique ()
    TriggerServerEvent('gcPhone:appelsDeleteAllHistorique')
end


--====================================================================================
--  Event NUI - Appels
--====================================================================================

RegisterNUICallback('startCall', function(data, cb)
    startCall(data.numero, data.rtcOffer, data.extraData)
    cb()
end)

RegisterNUICallback('acceptCall', function(data, cb)
    acceptCall(data.infoCall, data.rtcAnswer)
    cb()
end)
RegisterNUICallback('rejectCall', function(data, cb)
    rejectCall(data.infoCall)
    cb()
end)

RegisterNUICallback('ignoreCall', function(data, cb)
    ignoreCall(data.infoCall)
    cb()
end)

RegisterNUICallback('notififyUseRTC', function(use, cb)
    USE_RTC = use
    if USE_RTC == true and inCall == true then
        inCall = false
        Citizen.InvokeNative(0xE036A705F989E049)
        if Config.UseTokoVoIP then
            exports.tokovoip_script:removePlayerFromRadio(TokoVoipID)
            TokoVoipID = nil
        else
            NetworkSetTalkerProximity(2.5)
        end
    end
    cb()
end)

RegisterNUICallback('onCandidates', function(data, cb)
    TriggerServerEvent('gcPhone:candidates', data.id, data.candidates)
    cb()
end)

RegisterNetEvent("gcPhone:candidates")
AddEventHandler("gcPhone:candidates", function(candidates)
    SendNUIMessage({ event = 'candidatesAvailable', candidates = candidates })
end)

RegisterNetEvent('gcphone:autoCall')
AddEventHandler('gcphone:autoCall', function(number, extraData)
    if number ~= nil then
        SendNUIMessage({ event = "autoStartCall", number = number, extraData = extraData })
    end
end)

RegisterNetEvent('gcphone:autoCallNumber')
AddEventHandler('gcphone:autoCallNumber', function(data)
    TriggerEvent('gcphone:autoCall', data.number)
end)

RegisterNetEvent('gcphone:autoAcceptCall')
AddEventHandler('gcphone:autoAcceptCall', function(infoCall)
    SendNUIMessage({ event = "autoAcceptCall", infoCall = infoCall })
end)

--====================================================================================
--  Gestion des evenements NUI
--==================================================================================== 
RegisterNUICallback('log', function(data, cb)
    cb()
end)
RegisterNUICallback('focus', function(data, cb)
    cb()
end)
RegisterNUICallback('blur', function(data, cb)
    cb()
end)
RegisterNUICallback('reponseText', function(data, cb)
    local limit = data.limit or 255
    local text = data.text or ''

    DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "", text, "", "", "", limit)
    while (UpdateOnscreenKeyboard() == 0) do
        DisableAllControlActions(0);
        Wait(0);
    end
    if (GetOnscreenKeyboardResult()) then
        text = GetOnscreenKeyboardResult()
    end
    cb(json.encode({ text = text }))
end)
--====================================================================================
--  Event - Messages
--====================================================================================
RegisterNUICallback('getMessages', function(data, cb)
    cb(json.encode(messages))
end)
RegisterNUICallback('sendMessage', function(data, cb)
    if data.message == '%pos%' then
        local myPos = GetEntityCoords(PlayerPedId())
        data.message = 'GPS: ' .. myPos.x .. ', ' .. myPos.y
    end
    TriggerServerEvent('gcPhone:sendMessage', data.phoneNumber, data.message)
end)
RegisterNUICallback('deleteMessage', function(data, cb)
    deleteMessage(data.id)
    cb()
end)
RegisterNUICallback('deleteMessageNumber', function(data, cb)
    deleteMessageContact(data.number)
    cb()
end)
RegisterNUICallback('deleteAllMessage', function(data, cb)
    deleteAllMessage()
    cb()
end)
RegisterNUICallback('setReadMessageNumber', function(data, cb)
    setReadMessageNumber(data.number)
    cb()
end)
--====================================================================================
--  Event - Contacts
--====================================================================================
RegisterNUICallback('addContact', function(data, cb)
    TriggerServerEvent('gcPhone:addContact', data.display, data.phoneNumber)
end)
RegisterNUICallback('updateContact', function(data, cb)
    TriggerServerEvent('gcPhone:updateContact', data.id, data.display, data.phoneNumber)
end)
RegisterNUICallback('deleteContact', function(data, cb)
    TriggerServerEvent('gcPhone:deleteContact', data.id)
end)
RegisterNUICallback('getContacts', function(data, cb)
    cb(json.encode(contacts))
end)
RegisterNUICallback('setGPS', function(data, cb)
    SetNewWaypoint(tonumber(data.x), tonumber(data.y))
    cb()
end)

-- Add security for event (leuit#0100)
RegisterNUICallback('callEvent', function(data, cb)
    local eventName = data.eventName or ''
    if string.match(eventName, 'gcphone') then
        if data.data ~= nil then
            TriggerEvent(data.eventName, data.data)
        else
            TriggerEvent(data.eventName)
        end
    else
        print('Event not allowed')
    end
    cb()
end)
RegisterNUICallback('useMouse', function(um, cb)
    useMouse = um
end)
RegisterNUICallback('deleteALL', function(data, cb)
    TriggerServerEvent('gcPhone:deleteALL')
    cb()
end)

function TooglePhone()
    menuIsOpen = not menuIsOpen
    SendNUIMessage({ show = menuIsOpen })
    if menuIsOpen == true then
        PhonePlayIn()
        TriggerEvent('gcPhone:setMenuStatus', true)
        SetBigmapActive(1, 0)
    else
        PhonePlayOut()
        TriggerEvent('gcPhone:setMenuStatus', false)
        SetBigmapActive(0, 0)
    end
end
RegisterNUICallback('faketakePhoto', function(data, cb)
    menuIsOpen = false
    TriggerEvent('gcPhone:setMenuStatus', false)
    SendNUIMessage({ show = false })
    cb()
    TriggerEvent('camera:open')
end)

RegisterNUICallback('closePhone', function(data, cb)
    menuIsOpen = false
    TriggerEvent('gcPhone:setMenuStatus', false)
    SendNUIMessage({ show = false })
    PhonePlayOut()
    SetBigmapActive(0, 0)
    cb()
end)

----------------------------------
---------- GESTION APPEL ---------
----------------------------------
RegisterNUICallback('appelsDeleteHistorique', function(data, cb)
    appelsDeleteHistorique(data.numero)
    cb()
end)
RegisterNUICallback('appelsDeleteAllHistorique', function(data, cb)
    appelsDeleteAllHistorique(data.infoCall)
    cb()
end)

----------------------------------
---------- GESTION VIA WEBRTC ----
----------------------------------
AddEventHandler('onClientResourceStart', function(res)
    DoScreenFadeIn(300)
    if res == "gcphone" then
        --TriggerServerEvent('gcPhone:allUpdate')
        -- Try again in 2 minutes (Recovers bugged phone numbers)
        --Citizen.Wait(120000)
        --TriggerServerEvent('gcPhone:allUpdate')
    end
end)

RegisterNUICallback('setIgnoreFocus', function(data, cb)
    ignoreFocus = data.ignoreFocus
    cb()
end)

RegisterNUICallback('takePhoto', function(data, cb)
    CreateMobilePhone(1)
    CellCamActivate(true, true)
    takePhoto = true
    Citizen.Wait(0)
    if hasFocus == true then
        SetNuiFocus(false, false)
        hasFocus = false
    end
    while takePhoto do
        Citizen.Wait(0)

        if IsControlJustPressed(1, 27) then
            -- Toogle Mode
            frontCam = not frontCam
            CellFrontCamActivate(frontCam)
        elseif IsControlJustPressed(1, 177) then
            -- CANCEL
            DestroyMobilePhone()
            CellCamActivate(false, false)
            cb(json.encode({ url = nil }))
            takePhoto = false
            break
        elseif IsControlJustPressed(1, 176) then
            -- TAKE.. PIC
            exports['screenshot-basic']:requestScreenshotUpload(data.url, data.field, function(data)
                local resp = json.decode(data)
                DestroyMobilePhone()
                CellCamActivate(false, false)
                cb(json.encode({ url = resp.url }))
            end)
            takePhoto = false
        end
        HideHudComponentThisFrame(7)
        HideHudComponentThisFrame(8)
        HideHudComponentThisFrame(9)
        HideHudComponentThisFrame(6)
        HideHudComponentThisFrame(19)
        HideHudAndRadarThisFrame()
    end
    Citizen.Wait(1000)
    PhonePlayAnim('text', false, true)
end)