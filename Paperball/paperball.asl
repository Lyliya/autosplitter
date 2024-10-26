state("Paperball")
{
    float stageTime : "mono-2.0-bdwgc.dll", 0x004A7698, 0x230, 0x230, 0x2B0, 0xCE0, 0x30, 0x18, 0x10;
}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.LoadSceneManager = true;
    vars.Helper.GameName = "Paperball";
    vars.Helper.AlertGameTime();
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono => {
        vars.Helper["stageIndex"] = mono.Make<int>("StageController", "_controller", "_currentStageIndex");
        vars.Helper["gameMode"] = mono.Make<int>("GameController", "_controller", "_gameMode");
        var p = mono["Player"];
        var rc = mono["RunController"];
        vars.Helper["stageFinished"] = mono.Make<bool>("Player", "_players", 0x18, 0x30, p["_runController"], rc["_stageFinished"]);
        return true;
    });
}

onStart
{
}

gameTime
{
    if (current.stageTime < 0) return;
    if (current.stageTime > old.stageTime) return TimeSpan.FromSeconds(current.stageTime);
}

split {
    if (current.stageTime < 0) return;
    return (old.stageFinished == false && current.stageFinished == true);
}

isLoading
{
    return true;
}

start
{
    if (current.stageTime < 0) return;
    return (old.stageTime == 0 && current.stageTime > old.stageTime);
}

update
{
}