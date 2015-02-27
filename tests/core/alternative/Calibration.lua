
return{
	Calibration = function(unitTest)
		local MyModel = Model{
			x = 1,
			setup = function(self)
				self.t = Timer{
					Event{action = function()
						self.value = 2 * self.x ^2 - 3 * self.x + 4
					end}
				}
			end
		}

		local error_func = function()
			c = Calibration{
				finalTime = 1,
				parameters = {x ={ min = -100, max = 100}},
				fit = function(model)
					return model.value
				end
			}
		end
		unitTest:assert_error(error_func, mandatoryArgumentMsg("model"))	

		error_func = function()
			c = Calibration{
				model = MyModel,
				finalTime = 1,
				fit = function(model)
					return model.value
				end
			}
		end
		unitTest:assert_error(error_func, mandatoryArgumentMsg("parameters"))	

		error_func = function()
			local c = Calibration{
				model = MyModel,
				finalTime = 1,
				parameters = {x ={ min = -100, max = 100}},
			}
			c:fit(model, parameters)
		end
		unitTest:assert_error(error_func, "Function 'fit' was not implemented.")	
	end
}

