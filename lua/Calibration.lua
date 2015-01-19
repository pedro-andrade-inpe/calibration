local testRecursive


-- function used in execute() to test the model with all the possible combinations of parameters.
-- Params: Table with all the parameters and it's ranges or values indexed by number.
-- In the example: Params[1] = {x, -100, 100, (...)}
-- (It also contains some extra information such as the step increase 
-- or if that parameter varies according to a min/max range.)
-- best: The smallest fitness of the model tested.
-- a: the parameter that the function is currently variating. In the Example: [a] = [1] => x, [a] = [2]=> y.
-- Variables: The value that a parameter is being tested. Example: Variables = {x = -100, y = 1}

testRecursive  = function(self, Params, best, a, variables)
	if Params[a]["ranged"] == true then -- if the parameter uses a range of values
		for parameter = Params[a]["min"],  Params[a]["max"], Params[a]["step"] do	-- Testing the parameter with each value in it's range.
			variables[Params[a]["id"]] = parameter -- giving the variables table the current parameter and value being tested.
			local mVariables = {} -- copy of the variables table to be used in the model.
			forEachOrderedElement(variables, function(idx, attribute, atype)
				mVariables[idx] = attribute
			end)

			if a == #Params then -- if all parameters have already been given a value to be tested.
				local m = self.model(mVariables) --testing the model with it's current parameter values.
				m:execute(self.finalTime)
				local candidate = self.fit(m)
				if candidate < best then
					best = candidate
				end

			else  -- else, go to the next parameter to test it with it's range of values.
				best = testRecursive(self, Params, best, a+1, variables)
			end
		end

	else -- if the parameter uses a table of multiple values
		forEachOrderedElement(Params[a]["elements"], function (idx, attribute, atype) 
			-- Testing the parameter with each value in it's table.
			variables[Params[a]["id"]] = attribute
			local mVariables = {} -- copy of the variables table to be used in the model.
			forEachOrderedElement(variables, function(idx2, attribute2, atype2)
				mVariables[idx2] = attribute2
			end)

			if a == #Params then -- if all parameters have already been given a value to be tested.
				local m = self.model(mVariables) --testing the model with it's current parameter values.
				m:execute(self.finalTime)
				local candidate = self.fit(m)
				if candidate < best then
					best = candidate
				end

			else  -- else, go to the next parameter to test it with each of it possible values.
				best = testRecursive(self, Params, best, a+1, variables)
			end
		end)
	end
	return best
end


--@header Model Calibration functions.

Calibration_ = {
	type_ = "Calibration",
	--- Returns the fitness of a model, function must be implemented by the user
	-- @arg model Model fo calibration
	-- @arg parameter A Table with the parameters of the model.
	-- @usage c:fit(model, parameter)
	fit = function(model, parameter)
		customError("Function 'fit' was not implemented.")
	end,
	--- Executes and test the fitness of the model, 
	-- and then returns the parameter which generated the smaller fitness value.
	-- If the variable: "parameters" contains a parameter with a table with min and max
	-- it tests the model for each of the values between self.parameters.min and self.parameters.max,
	-- If the variable: "parameters" contains a parameter with a table of multiple values,
	-- it tests the model with all the possible combinations of these values.
	-- @usage  c = Calibration{
	-- 		...
	--	}
	--
	-- c:execute()
	execute = function(self)
			local startParams = {} 
			-- A table with the first possible values for the parameters to be tested.
			forEachOrderedElement(self.parameters, function(idx, attribute, atype)
				if self.parameters[idx]["min"] ~= nil then
    				startParams[idx] = self.parameters[idx]["min"]
    			else
    				startParams[idx] = self.parameters[idx][0]
    			end
			end)

			local Params = {} 
			if self.SAMDE == nil then
				self.SAMDE = false
			end
			-- The possible values for each parameter is being put in a table indexed by numbers.
			forEachOrderedElement(self.parameters, function (idx, attribute, atype)
				local range = true
				local steps = 1
				if self.parameters[idx]["step"] ~= nil then
					steps = self.parameters[idx]["step"]
				end
				if self.parameters[idx]["min"] == nil or self.parameters[idx]["max"] == nil then
					range = false
				end
				Params[#Params+1] = {id = idx, min = self.parameters[idx]["min"], 
				max = self.parameters[idx]["max"], elements = attribute, ranged = range, step = steps}
			end)

			local m = self.model(startParams) -- test the model with it's first possible values
			m:execute(self.finalTime)
			local best = self.fit(m)
			local variables = {}
			if self.SAMDE == true then
				local samdeValues = {}
				local samdeParam = {}
				local SamdeParamQuant = 0
				forEachOrderedElement(self.parameters, function (idx, attribute, atype)
					samdeParam[#samdeParam+1] = idx
					samdeValues[#samdeValues+1] = {self.parameters[idx]["min"], self.parameters[idx]["max"]}
					SamdeParamQuant = SamdeParamQuant + 1
				end)

				best = calibration(samdeValues, SamdeParamQuant, self.model, samdeParam)
			else
				best = testRecursive(self, Params, best, 1, variables)
			end
			
			-- use a recursive function to test the model with all possible values
			return best -- returns the smallest fitness
	end
}

metaTableCalibration_ = {
	__index = Calibration_
}

---Type to calibrate a model, returns a calibration type with it's functions.
-- @arg data a Table containing: A model constructor, with the model that will be calibrated,
-- and a table with (min, max, step) of the range in which the model will be calibrated 
-- or a table with multiple values to be tested.
-- @usage c = Calibration{
--     model = MyModel,
--     parameters = {x = {min = 1, max = 10, step = 2}},
--     fit = function(model, parameter)
--     		...	
--     end
-- }
-- 
--c = Calibration{
--     model = MyModel,
--     parameters = { x = {1, 3, 4, 7}},
--     fit = function(model, parameter)
--     		...	
--     end
-- }
function Calibration(data)
	setmetatable(data, metaTableCalibration_)
	mandatoryTableArgument(data, "model", "function")
	mandatoryTableArgument(data, "parameters", "table")
	mandatoryTableArgument(data, "finalTime", "number")
	return data
end
