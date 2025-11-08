function love.load()
	love.window.setTitle("Hello World")
	love.window.setMode(800, 600)
	print("Hello, World!")
end

function love.update() end

function love.draw()
	love.graphics.printf("Hello, World!", 0, love.graphics.getHeight() / 2, love.graphics.getWidth(), "center")
end
