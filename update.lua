-- List of URLs to download
local urls = {
	"https://raw.githubusercontent.com/DFC-Siege/MiningTurtle/refs/heads/main/MiningTurle.lua",
}

for _, url in ipairs(urls) do
	-- Extract the filename from the URL
	local filename = url:match("^.+/(.+)$")
	print(filename)
	if filename then
		-- Delete the file if it exists
		if fs.exists("/programs/" .. filename) then
			fs.delete(filename)
			print("Deleted existing file: " .. filename)
		end

		-- Download the file
		local success, err = shell.run("wget", url, filename)
		if success then
			print("Downloaded: " .. filename)
		else
			print("Failed to download " .. filename .. ": " .. tostring(err))
		end
	else
		print("Invalid URL format: " .. url)
	end
end
