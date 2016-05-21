TextBox = TextBox or class(Item)

function TextBox:init( parent, params )	
	params.value = params.value or ""
	self.super.init( self, parent, params )
    self.type = "TextBox"
	local bg = params.panel:bitmap({
        name = "textbg",
        x = -2,
        w = params.panel:w() / 1.5,
        h = params.items_size,
        layer = 5,
        color = Color(0.5, 0.5, 0.5),
    })	
    local text = params.panel:text({
	    name = "text",
	    text = tostring(params.value),
	    valign = "center",
	    vertical = "center",
        w = bg:w() - 4,
		wrap = true,
		word_wrap = true,        
	    h = params.items_size - 2,
	    layer = 8,
	    color = params.text_color or Color.black,
	    font = parent.font or "fonts/font_medium_mf",
	    font_size = params.items_size - 2
	}) 	
	text:set_selection(text:text():len())		
    local caret = params.panel:rect({
        name = "caret",
        w = 1,
        h = params.items_size - 2,
       	alpha = 0,
        layer = 9,
    })			
    text:enter_text(callback(self, self, "enter_text"))	
    caret:animate(callback(self, self, "blink"))
    bg:set_right(params.panel:w())
    text:set_center(bg:center())
end


function TextBox:SetValue(value, reset_selection)
	local text = self.panel:child("text")
	text:set_text(value)
	if reset_selection then
		text:set_selection(text:text():len())		
	end
	self:update_caret()
	self.super.SetValue(self, value)
end
function TextBox:CheckText(text)
    if self.filter == "number" then
        if tonumber(text:text()) ~= nil then
            if self.max or self.min then
                self:SetValue(math.clamp(tonumber(text:text()), self.min or tonumber(text:text()), self.max or tonumber(text:text())), true)
            else
                self:SetValue(tonumber(text:text()), true)
            end
        else
            self:SetValue(tonumber(self._before_text), true, true)
        end
    else
        self:SetValue(text:text(), true)
    end     
end 
function TextBox:blink( caret )
	local t = 2
	while true do
		local dt = coroutine.yield()
 		t = t - dt	
 		local cv = math.sin( t * 200 ) 
		local col = math.lerp(0, 1, cv)
		caret:set_alpha(self.cantype and math.lerp(0, 1, cv) or 0)
 	end
end
function TextBox:key_hold( text, k )
  	while self.cantype and self.menu.key_pressed == k and self.menu._highlighted == self do		
		local s, e = text:selection()
		local n = utf8.len(text:text())
		if Input:keyboard():down(Idstring("left ctrl")) then
	    	if Input:keyboard():down(Idstring("a")) then
	    		text:set_selection(0, text:text():len())
	    	elseif Input:keyboard():down(Idstring("c")) then
	    		Application:set_clipboard(tostring(text:selected_text())) 
	    	elseif Input:keyboard():down(Idstring("v")) then
	    		if (self.filter == "number" and tonumber(Application:get_clipboard()) == nil) then
	    			return
	    		end
	    		self._before_text = text:text()
				text:replace_text(tostring(Application:get_clipboard()))
				self.value = self.filter == "number" and tonumber(text:text()) or text:text()				
				if self.callback then
					self.callback(self.parent, self)
				end				
			elseif Input:keyboard():down(Idstring("z")) and self._before_text then
				local before_text = self._before_text
				self._before_text = text:text()
				self:SetValue(before_text)	
				if self.callback then
					self.callback(self.parent, self)
				end							
	    	end
	    elseif Input:keyboard():down(Idstring("left shift")) then
	  	    if Input:keyboard():down(Idstring("left")) then
				text:set_selection(s - 1, e)
			elseif Input:keyboard():down(Idstring("right")) then
				text:set_selection(s, e + 1)  	
			end
	    else	
		    if k == Idstring("backspace") then		
		    	if not (utf8.len(text:text()) < 1) then
					if s == e and s > 0 then
						text:set_selection(s - 1, e)
					end
					self._before_text = text:text()
					text:replace_text("")      
				end 
				self.value = text:text()	
				if self.callback then
					self.callback(self.parent, self)
				end
		    elseif k == Idstring("left") then
				if s < e then
					text:set_selection(s, s)
				elseif s > 0 then
					text:set_selection(s - 1, s - 1)
				end
			elseif k == Idstring("right") then
				if s < e then
					text:set_selection(e, e)
				elseif s < n then
					text:set_selection(s + 1, s + 1)
				end	
			else
				self.menu.key_pressed = nil
		    end	  		
	    end		
		self:update_caret()	
	    wait(0.2)
  	end
end
  
function TextBox:enter_text( text, s )
    local number = self.filter == "number"
    if self.menu._menu_closed or (number and tonumber(s) == nil and s ~= "-" and s ~= ".") then
        return
    end
    if self.menu._highlighted == self and self.cantype and not Input:keyboard():down(Idstring("left ctrl")) then
        self._before_text = number and (tonumber(text:text()) ~= nil and tonumber(text:text()) or self._before_text) or text:text()
        text:replace_text(s)
        self:update_caret() 
        local txt = not number and text:text() or tonumber(text:text())
        if self.callback and tostring(txt) == text:text() then
            self:SetValue(txt, false, true)
            self.callback(self.parent, self)
        end
    end     
end

function TextBox:mouse_pressed( button, x, y )
	if not alive(self.panel) then
		return
	end
	self.cantype = self.panel:inside(x,y) and button == Idstring("0")
	self:update_caret()	
	if not self.cantype then
		self:SetValue(self.panel:child("text"):text(), true)
	end		
	return self.cantype
end

function TextBox:key_press( o, k )	
	local text = self.panel:child("text")
	if self.cantype then 
 		text:animate(callback(self, self, "key_hold"), k)
 	end
 	if k == Idstring("enter") then
 		self.cantype = false
 		self:CheckText(text)
 	end
	self:update_caret()		
end
 
function TextBox:update_caret()		
	local text = self.panel:child("text")
	local lines = math.max(1,text:number_of_lines())
	self.panel:child("textbg"):set_h( self.items_size * lines)
	self.panel:child("text"):set_h((self.items_size - 2) * lines)
 	self.panel:set_h( self.items_size * lines )
	self.panel:child("text"):set_center(self.panel:child("textbg"):center())
    if self.group then
        self.group:AlignItems()
    else
        self.parent:AlignItems()
    end
	
	local s, e = text:selection()
	local x, y, w, h = text:selection_rect()
	if s == 0 and e == 0 then
		x = text:world_x()
		y = text:world_y()
	end
	self.panel:child("caret"):set_world_position(x, y + 1)
	self.panel:child("caret"):set_visible(self.cantype)
end

function TextBox:mouse_moved( x, y )
    self.super.mouse_moved(self, x, y)
    local text = self.panel:child("text")
    local cantype = self.cantype
    self.cantype = self.panel:inside(x,y) and self.cantype or false 
    if cantype and not self.cantype then
        self:CheckText(text)
    end 
    self.panel:child("caret"):set_visible(self.cantype)
    
    if self.cantype then
        self:SetValue(text:text())
    end
end
 

function TextBox:mouse_released( button, x, y )
    self.super.mouse_released( self, button, x, y )
end 