



Identify_obj = oo.class(nil, "Identify_obj")

function Identify_obj:__init(char_id)
	self.char_id = char_id
	self.letters = ""
	self.counts = 0
	self.time = ev.time
end

function Identify_obj:set_letters(letters)
	self.letters = letters or ""
end

function Identify_obj:get_letters()
	return self.letters
end

function Identify_obj:set_time(time)
	self.time = time
end

function Identify_obj:get_time()
	return self.time
end

function Identify_obj:add_counts(counts)
	self.counts = self.counts+counts
end

function Identify_obj:get_counts()
	return self.counts
end
