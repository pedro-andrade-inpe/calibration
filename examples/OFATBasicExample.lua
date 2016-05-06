-- @example Basic example for testing SAMDE type
-- using a SysDyn model.
import("calibration")
import("ca")
abm = Wolfram
testParameters = {rule = Choice{min = 0, max = 255, points = 11}}
referenceData = {
    folderName = tmpDir(),
    quantity = 2,
    model = abm,
    -- hideGraphs = true,
    -- If this is true, observers are turned off but model does not work. I think this is a bug in terrame disableGraphs().
    parameters = {rule = Choice{0,10,25,50, 125, 200}},
    output = function ( model )
        counter = 0
        forEachOrderedElement(model.cs.cells, function(id, at, ty)
            if at.state == "alive" then
                counter = counter + 1
            end
        end)
        return counter
    end
}

sensivityTest = OFATSensitivity(referenceData, testParameters)

print("END")