-- select the csv to import to iCloud keychain
set theFile to (choose file with prompt "Select the CSV file")

on makePass(sURL, sUsername, sPass)
	script thePass
		property kcURL : sURL
		property kcUsername : sUsername
		property kcPassword : sPass
		
		on asText()
			return kcURL & "," & kcUsername & "," & kcPassword & "
"
		end asText
		
	end script
	return thePass
end makePass

-- read csv file
set f to read theFile

-- split lines into records
set recs to paragraphs of f

-- getting values for each record
set passwords to {}
set AppleScript's text item delimiters to ","
set notAddedList to {}
repeat with i from 1 to length of recs
	try
		-- ignore item 1 "name"
		set kcURL to text item 2 of (item i of recs)
		set kcUsername to text item 3 of (item i of recs)
		set kcPassword to text item 4 of (item i of recs)
		
		set val to makePass(kcURL, kcUsername, kcPassword)
		
		set end of passwords to val
	end try
end repeat

if length of passwords = 0 then
	display dialog "Cannot read passwords from " & theFile
end if

on listToText(kcList, kcDescription)
	set output to kcDescription & "
" as text
	repeat with i in kcList
		set output to output & i's asText()
		-- tell i "asText" of i
	end repeat
	return output
end listToText

on showListInTextEdit(kcList, kcDescription)
	tell application "TextEdit"
		activate
		set output to my listToText(kcList, kcDescription)
		make new document with properties {text:output}
	end tell
end showListInTextEdit

-- open safari passwords screen, check it is unlocked, do not allow to proceed until it is unlocked or user clicks cancel.
tell application "System Events"
	tell application process "Safari"
		set frontmost to true
		keystroke "," using command down
		tell window 1
			click button 4 of toolbar 1 of it
			repeat until (exists button 3 of group 1 of group 1 of it)
				if not (exists button 3 of group 1 of group 1 of it) then
					display dialog "To begin importing, unlock Safari passwords then click OK. Please do not use your computer until the process has completed." with title "CSV to iCloud Keychain"
				end if
			end repeat
		end tell
	end tell
end tell


repeat with i in passwords
	-- write kcURL, kcUsername and kcPassword into text fields of safari passwords
	tell application "System Events"
		tell application process "Safari"
			set frontmost to true
			tell window 1
				
				click button 3 of group 1 of group 1 of it
				-- write fields
				tell sheet 1 of it
					set focused of text field 1 to true
					set value of text field 1 of it to (kcURL of i)
					keystroke tab
					
					set value of text field 2 of it to (kcUsername of i)
					keystroke tab
					set value of text field 3 of it to (kcPassword of i)
					
					set props to get every attribute of button 1
					set isEnabled to the value of attribute "AXEnabled" of button 1
					-- set enabled to text item AXEnabled of(prop i of props)
					-- display dialog isEnabled
					
					if isEnabled then
						keystroke return
					else
						key code 53
						set end of notAddedList to i
					end if
				end tell
			end tell
		end tell
	end tell
end repeat

if (count of notAddedList) > 0 then
	my showListInTextEdit(notAddedList, "This passwords were not added to Safari")
	display dialog "List of not added passwords was shown in TextEdit"
end if
