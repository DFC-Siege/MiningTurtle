-- List of URLs to download
local urls = {
	"https://raw.githubusercontent.com/DFC-Siege/MiningTurtle/main/MiningTurtle.lua",
	"https://raw.githubusercontent.com/DFC-Siege/MiningTurtle/main/farmer.lua",
	-- Add more URLs as needed
}

for _, url in ipairs(urls) do
	-- Extract the filename from the URL
	local filename = url:match("^.+/(.+)$")
	if filename then
		-- Define the full path for the file
		local filepath = shell.resolve(filename)

		-- Delete the file if it exists
		if fs.exists(filepath) then
			fs.delete(filepath)
			print("Deleted existing file: " .. filepath)
		end

		-- Perform the HTTP GET request
		local response = http.get(url)
		if response then
			-- Open the file in write mode
			local file = fs.open(filepath, "w")
			if file then
				-- Write the contents to the file
				file.write(response.readAll())
				file.close()
				print("Downloaded: " .. filepath)
			else
				print("Failed to open file for writing: " .. filepath)
			end
			response.close()
		else
			print("Failed to download: " .. url)
		end
	else
		print("Invalid URL format: " .. url)
	end
end
