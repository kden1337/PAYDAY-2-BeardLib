Hooks:PostHook(Setup, "init_managers", "BeardLibAddMissingDLCPackages", function(ply)
    managers.dlc:give_missing_package()

    while #BeardLib._files_to_load > 0 do
        local ext_ids, path_ids = unpack(table.remove(BeardLib._files_to_load))
        BeardLib:LoadAsset(ext_ids, path_ids)
    end
end)
