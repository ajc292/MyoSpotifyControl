-- SpotifyControlv2
-- Myo Script to allow the Thalmic Myo Armband to send music commands through the Myo Connect app to control Spotify

scriptId = 'com.ajc292.myoDev.SpotifyControlv2'

function playpause()
    myo.keyboard("space", "press")
end

function Forward()
	myo.keyboard("right_arrow", "press", "command")
end

function Backward()
	myo.keyboard("left_arrow", "press", "command")
end

function volUp()
    myo.keyboard("up_arrow","down", "command")
end

function volDown()
    myo.keyboard("down_arrow","down", "command")
end

function resetFist()
    fistMade = false
    referenceRoll = myo.getRoll()
    currentRoll = referenceRoll
  	myo.keyboard("up_arrow","up")
    myo.keyboard("down_arrow","up")
end

-- Makes use of myo.getArm() to swap wave out and wave in when the armband is being worn on
-- the left arm. This allows us to treat wave out as wave right and wave in as wave
-- left for consistent direction. The function has no effect on other poses.
function conditionallySwapWave(pose)
    if myo.getArm() == "left" then
        if pose == "waveIn" then
            pose = "waveOut"
        elseif pose == "waveOut" then
            pose = "waveIn"
        end
    end
    return pose
end

function unlock()
    unlocked = true
    extendUnlock()
end

function extendUnlock()
    unlockedSince = myo.getTimeMilliseconds()
end

-- All timeouts in milliseconds
UNLOCKED_TIMEOUT = 5000               -- Time since last activity before we lock

function onPoseEdge(pose, edge)

    if pose == "thumbToPinky" then
        if edge == "off" then
            -- Unlock when pose is released in case the user holds it for a while.
            unlock()

        elseif edge == "on" and not unlocked then
            -- Vibrate twice on unlock.
            -- We do this when the pose is made for better feedback.
            myo.vibrate("short")
            myo.vibrate("short")
            extendUnlock()
        end
    end
    
	if pose == "waveIn" or pose == "waveOut" or pose == "fist" or pose == "fingersSpread" then
        local now = myo.getTimeMilliseconds()

        if unlocked and edge == "on" then
            -- Deal with direction and arm.
            pose = conditionallySwapWave(pose)

            -- Determine direction based on the pose.
            if pose == "waveIn" then
                Backward()
			
			
			elseif pose == "fingersSpread" then
				playpause()
			
            
			elseif pose == "fist" then -- Sets up fist movement
            	
                if not fistMade then
                    referenceRoll = myo.getRoll()
                    fistMade = true
                    if myo.getXDirection() == "towardElbow" then -- Adjusts for Myo orientation
                        referenceRoll = referenceRoll * -1
                    end
                end

            elseif pose == "waveOut" then
            	Forward()
            end

            if pose ~= "fist" then -- Reset call
                resetFist()
            end

            -- Initial burst and vibrate
            myo.vibrate("short")
            extendUnlock()
        end
    end
end

function onPeriodic()
    local now = myo.getTimeMilliseconds()

    -- ...

    -- Lock after inactivity
    if unlocked then
        -- If we've been unlocked longer than the timeout period, lock.
        -- Activity will update unlockedSince, see extendUnlock() above.
        if (now - unlockedSince) > UNLOCKED_TIMEOUT then
            unlocked = false
        end
    end

    currentRoll = myo.getRoll()
    if myo.getXDirection() == "towardElbow" then
        currentRoll = currentRoll * -1
        extendUnlock()
    end

    if unlocked and fistMade then -- Moves page when fist is held and Myo is rotated
        extendUnlock()
        subtractive = currentRoll - referenceRoll
        if subtractive > 0.2  then
            volUp()
        elseif subtractive < -0.2 then
            volDown() 
        end
    end

end


function onForegroundWindowChange(app, title)
    -- Here we decide if we want to control the new active app.
	local wantActive = false
	
	if platfrom =="MacOS" then
    	if app == "com.spotify.client" then
    		wantActive = true
			activeApp = "Spotify"
		end
	end
    
    return wantActive
end

function activeAppName()
    -- Return the active app name determined in onForegroundWindowChange
    return activeApp
end

function onActiveChange(isActive)
    if not isActive then
        unlocked = false
    end
end
