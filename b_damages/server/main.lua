ESX = exports.es_extended:getSharedObject()

ESX.RegisterServerCallback('b_damages:getOwnerOfDamage', function(source, cb)

    local idOwner = NetworkGetEntityOwner(GetPedSourceOfDamage(GetPlayerPed(source)))

    cb(idOwner or false)

end)