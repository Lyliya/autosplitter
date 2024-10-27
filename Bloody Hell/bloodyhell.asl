state("Bloody Hell") {
    float porkchopHealth : "UnityPlayer.dll", 0x019C0548, 0x0, 0x3B8, 0x0, 0x38, 0x60, 0x28, 0xB8;
    bool inGodHaloRange : "UnityPlayer.dll", 0x019BCC08, 0xB70, 0xF88, 0x108, 0xC0, 0xE0, 0x60, 0xD0;
}

startup {
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.LoadSceneManager = true;
    vars.Helper.GameName = "Bloody Hell";

    settings.Add("abilities", true, "Abilities");
    settings.Add("abilities_dash", true, "Dash", "abilities");
    settings.Add("abilities_charging_shot", true, "Charging Shot", "abilities");
    settings.Add("abilities_double_dash", true, "Double Dash", "abilities");
    settings.Add("abilities_grappling", true, "Grappling", "abilities");

    settings.Add("boss", true, "Boss");
    settings.Add("boss_satan", true, "Satan", "boss");
    settings.Add("boss_porkchop", true, "Porkchop", "boss");

    settings.Add("skips", false, "Skips");
    settings.Add("skip_porkchop", false, "Porkchop skip", "skips");
    settings.Add("skip_laser", false, "Laser skip skip", "skips");
}

init {
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono => {
        mono.Images.Clear();
        
        vars.Helper["abilitiesMemory"] = mono.MakeList<IntPtr>("Systems", 1, "Instance", "CurrentSaveFileData", "UnlockedAbilities");
        vars.Helper["pressedInteract"] = mono.Make<bool>("InputHandler", 1, "Instance", "CurrentFrame", "PressedInteract");
        vars.Helper["currentRoom"] = mono.MakeString("Systems", 1, "Instance", "CurrentRoomManager", "RoomData", "SceneName");
        vars.Helper["isStarting"] = mono.Make<bool>("UIManager", 1, "Instance", "_starting");
        return true;
    });

    vars.porkchopKilled = false;
    vars.satanKilled = false;

    vars.porkchopSkip = false;
    vars.laserSkip = false;

    vars.dash = false;
    vars.chargingShot = false;
    vars.doubleDash = false;
    vars.grappling = false;

    current.abilities = new List<string>();
}

onStart
{
    current.abilities.Clear();
    vars.porkchopKilled = false;
    vars.satanKilled = false;
    vars.porkchopSkip = false;
    vars.laserSkip = false;
    vars.dash = false;
    vars.doubleDash = false;
    vars.chargingShot = false;
    vars.grappling = false;
}

split
{
    // Split on dash pickup
    if (!vars.dash && !old.abilities.Contains("Player_State_Dashing") && current.abilities.Contains("Player_State_Dashing"))
    {
        vars.dash = true;
        return settings["abilities_dash"];
    }

    // Split on charging shot pickup
    if (!vars.chargingShot && !old.abilities.Contains("Player_State_ChargingShot") && current.abilities.Contains("Player_State_ChargingShot"))
    {
        vars.chargingShot = true;
        return settings["abilities_charging_shot"];
    }

    // Split on double dash pickup
    if (!vars.doubleDash && !old.abilities.Contains("Player_State_DoubleDashing") && current.abilities.Contains("Player_State_DoubleDashing"))
    {
        vars.doubleDash = true;
        return settings["abilities_double_dash"];
    }

    // Split on grappling pickup
    if (!vars.grappling && !old.abilities.Contains("Player_State_Grappling") && current.abilities.Contains("Player_State_Grappling"))
    {
        vars.grappling = true;
        return settings["abilities_grappling"];
    }

    // Kill Porkchop
    if (!vars.porkchopKilled && old.porkchopHealth > 0 && old.porkchopHealth < 130 && current.porkchopHealth <= 0 && current.currentRoom == "Z1_R1_Bossfight_Porkchop") {
        vars.porkchopKilled = true;
        return settings["boss_porkchop"];
    }


    // Transition from Satan Room to End of game Heaven
    if (!vars.satanKilled && old.currentRoom == "Room_SatanTest.unity" && current.currentRoom == "Heaven_EndOfGame.unity") {
        vars.satanKilled = true;
        return settings["boss_satan"];
    }

    // Pick Up God Halo
    if ((old.inGodHaloRange == true || current.inGodHaloRange == true) && current.pressedInteract == true && current.currentRoom == "Room_Bossfight_God.unity") {
        return true;
    }

    // Porkchop skip
    if (!vars.porkchopSkip && old.currentRoom == "Z1_R1_Bossfight_Porkchop" && current.currentRoom == "Z1_R2_Bot.unity") {
        vars.porkchopSkip = true;
        return settings["skip_porkchop"];
    }

    // Laser skip skip
    if (!vars.laserSkip && old.currentRoom == "Z1_R3_Bot.unity" && current.currentRoom == "Z2_R1_Bot_SP.unity") {
        vars.laserSkip = true;
        return settings["skip_laser"];
    }


}

start
{
    if (((IDictionary<string, Object>)old).ContainsKey("isStarting"))
    {
        return !old.isStarting && current.isStarting;
    }
}

update
{
    current.abilities = ((List<IntPtr>)current.abilitiesMemory).Select(address =>
    {
        var length = vars.Helper.Read<int>(address + 0x10);
        var s = vars.Helper.ReadString(length * 2, ReadStringType.UTF16, address + 0x14);
        return s;
    })
    .ToList();
}
