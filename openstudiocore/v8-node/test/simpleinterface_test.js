var assert = require('assert')
var openstudio = require('../OpenStudio.js').openstudio;


var model = openstudio.model.exampleModel();

var results = openstudio.runmanager.RunManager.runSimulation(model, 
    new openstudio.runmanager.SimulationOptions(true, true, false, true, 2, 7, new openstudio.path(""), new openstudio.path(""), "Golden, CO, USA"));

var errors = results.getErrors();

assert(errors.is_initialized());

assert(errors.get().succeeded());

var energyPlusResults = results.getEnergyPlusFuelUses();
var isoModelResults = results.getISOFuelUses();

assert(energyPlusResults.size() > 0);
assert(isoModelResults.size() > 0);

var energyPlusUses = 0.0;
for (var i = 0; i < energyPlusResults.size(); ++i)
{
  energyPlusUses += energyPlusResults.get(i).second;
}
assert(energyPlusUses > 0.0);


var isoModelUses = 0.0;
for (var i = 0; i < isoModelResults.size(); ++i)
{
  isoModelUses += isoModelResults.get(i).second;
}
assert(isoModelUses > 0.0);
